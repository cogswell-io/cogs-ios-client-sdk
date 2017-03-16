//
//  PubSubConnectionHandle.swift
//  CogsSDK
//

/**
 * Copyright (C) 2017 Aviata Inc. All Rights Reserved.
 * This code is licensed under the Apache License 2.0
 *
 * This license can be found in the LICENSE.txt at or near the root of the
 * project or repository. It can also be found here:
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * You should have received a copy of the Apache License 2.0 license with this
 * code or source file. If not, please contact support@cogswell.io
 */

import Foundation
import Starscream

/// The result of pub/pub operation
///
/// - PubSubResponseError: The operation completed with error.
/// - PubSubSuccess: The operation completed successfully with response object.
public enum PubSubOutcome {
    /// Returns the error occured as `PubSubErrorResponse` object.
    case pubSubResponseError(PubSubErrorResponse)
    /// Returns the response object as `Any`.
    case pubSubSuccess(Any)
}


/// Pub/Sub connection handler
public final class PubSubConnectionHandle {

    private var currentReconnectDelay: Double
    private var currentReconnectAtempts: Int = 0
    private var autoReconnect: Bool

    private var webSocket : WebSocket
    private var options: PubSubOptions
    private var keys: [String]!
    private var sessionUUID: String?
    private var sequence: Int = 0
    
    private let lock = DispatchSemaphore(value: 1)
    private var handlerDispatcher = HandlersCache()
    private var callbackQueue = DispatchQueue.main

    private var channelHandlers = [String : (PubSubMessage) -> ()]()
    private var connectHandler: (() -> ())?
    
    /// New session event handler.
    ///
    /// Indicates that the session associated with this connection is not a resumed session, therefore there are no subscriptions associated with this session. If there had been a previous session and the connection was replaced by an auto-reconnect, the previous session was not restored resulting in all subscriptions being lost.
    public var onNewSession: ((String) -> ())?
    
    /// Reconnect event handler.
    ///
    /// The event is emitted on socket reconnection if it disconnected for any reason.
    public var onReconnect: (() -> ())?
    
    /// Raw record event handler.
    ///
    /// The event is emitted for every raw record received from the server, whether a response to a request or a message. This is mostly useful for debugging issues with server communication.
    public var onRawRecord: ((RawRecord) -> ())?
    
    /// Message event handler.
    ///
    /// The event is emitted whenever the socket receives messages from any channel.
    public var onMessage: ((PubSubMessage) -> ())?

    /// Close event handler
    public var onClose: ((Error?) -> ())?
    
    /// General error event handler.
    ///
    /// The event is emitted on any connection errors, failed publishes, or when any exception is thrown.
    public var onError: ((Error) -> ())?
    
    /// Response error event handler.
    ///
    /// The event is emitted whenever a message is sent to the user with an error status code.
    public var onErrorResponse: ((PubSubErrorResponse) -> ())?
    
    
    /// Initializes and returns a connection handler.
    ///
    /// - Parameters:
    ///   - keys: The provided project keys
    ///   - options: The connection options.
    public init(keys: [String], options: PubSubOptions?) {

        if let ops = options {
            self.options = ops
        } else {
            self.options = PubSubOptions.defaultOptions
        }
        
        self.keys                    = keys
        self.currentReconnectDelay   = self.options.minReconnectDelay
        self.autoReconnect           = self.options.autoReconnect

        webSocket = WebSocket(url: URL(string: self.options.url)!)
        webSocket.timeout = self.options.connectionTimeout
        
        webSocket.onConnect = {
            self.connectHandler?()
            self.autoReconnect         = self.options.autoReconnect
            self.currentReconnectDelay = self.options.minReconnectDelay
            self.currentReconnectAtempts = 0
            self.getSessionUuid{ _ in }
        }
        
        webSocket.onDisconnect = { (error: NSError?) in
            if let err = error, err.code != 1000 {
                self.onClose?(error)
            } else {
                self.onClose?(nil)
            }

            func scheduleReconnect() {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + self.currentReconnectDelay) {
                    self.reconnect()
                }
            }

            if self.autoReconnect {
                if self.options.maxReconnectAttempts > -1 {
                    guard self.currentReconnectAtempts < self.options.maxReconnectAttempts else { return }

                    scheduleReconnect()
                    self.currentReconnectAtempts += 1
                } else {
                    scheduleReconnect()
                }

                print(self.currentReconnectDelay)
                print(self.currentReconnectAtempts)

                self.currentReconnectDelay *= 2.0

                if self.currentReconnectDelay > self.options.maxReconnectDelay {
                    self.currentReconnectDelay = self.options.maxReconnectDelay
                }
            }
        }

        webSocket.onText = { (text: String) in
            self.onRawRecord?(text)
            
            DialectValidator.parseAndAutoValidate(record: text) { json, error, responseError in
                var seq: Int?
                var response: PubSubResponse?
                
                if let error = error {
                    self.onError?(error)
                } else if let respError = responseError {
                    seq = respError.sequence
                    self.onErrorResponse?(respError)
                } else if let j = json {
                    do {
                        response = try PubSubResponse(json: j)
                        seq = response?.seq
   
                        if let sessionUUID = response?.uuid {
                            if sessionUUID == self.sessionUUID {
                                self.onReconnect?()
                            } else {
                                self.onNewSession?(sessionUUID)
                            }

                            self.sessionUUID = sessionUUID
                        }
                    } catch {
                        do {
                            let message = try PubSubMessage(json: j)
                            self.channelHandlers[message.channel]?(message)
                            self.onMessage?(message)
                        } catch {
                            self.onError?(error)
                        }
                    }
                }
                
                // call method's completion handler
                self.callbackQueue.async { [weak self] in
                    guard let weakSelf = self else { return }
                    
                    if let sequence = seq, let completion = weakSelf.handlerDispatcher.object(forKey: sequence),
                        let closure = completion.closure {
                        completion.completed = true
                        closure(response, responseError)
                        _ = weakSelf.handlerDispatcher.removeObject(forKey: sequence)
                    }
                }
            }
        }
        
        handlerDispatcher.dispose = { handler, sequence in
            if (handler.completed != true && handler.disposable){
                if let closure = handler.closure {
                    closure(nil, PubSubErrorResponse(code: Int(101), message: "Timeout awaiting response to sequence \(sequence)"))
                }
                
                let error = NSError(domain: "CogsSDKError - Timeout", code: Int(101), userInfo: [NSLocalizedDescriptionKey: "Timeout awaiting response to sequence \(sequence)"])
                self.onError?(error)
            }
        }
    }
    
    /// Starts connection with the websocket.
    ///
    /// - Parameter sessionUUID: When supplied client session will be restored if possible.
    public func connect(sessionUUID: String?, completion: (() -> ())? = nil) {
        
        self.sessionUUID = sessionUUID
        self.connectHandler = completion
        
        let headers = SocketAuthentication.authenticate(keys: keys, sessionUUID: self.sessionUUID)
        
        webSocket.headers["Payload"] = headers.payloadBase64
        webSocket.headers["PayloadHMAC"] = headers.payloadHmac
        
        webSocket.connect()
    }

    /// Drops connection.
    public func dropConnection() {
        if webSocket.isConnected {

            webSocket.disconnect()
            handlerDispatcher.removeAllObjects()
        }
    }
    
    ///  Disconnects from the websocket.
    public func close() {
        if webSocket.isConnected {
            self.autoReconnect = false

            webSocket.disconnect()
            handlerDispatcher.removeAllObjects()
        }
    }
    
    /// Getts session UUID.
    ///
    /// - Parameter completion: The closure called when the `getSessionUuid` is complete.
    public func getSessionUuid(completion: @escaping (PubSubOutcome) -> ()) {
        
        let seq = incrementSequence()
        
        func completionHandler(response: PubSubResponse?, error: PubSubErrorResponse?) -> (){
            if let err = error {
                completion(PubSubOutcome.pubSubResponseError(err))
            } else {
                if let result = response {
                    completion(PubSubOutcome.pubSubSuccess(result.uuid as Any))
                }
            }
        }
        
        handlerDispatcher.setObject(Handler(completionHandler), forKey: seq)
        
        let params: [String: Any] = [
            "seq": seq ,
            "action": "session-uuid"
        ]

        writeToSocket(params: params)
    }
    

    /// Subscribes to a channel.
    ///
    /// The successful result contains a list of the subscribed channels. The connection needs read permissions in order to subscribe to a channel.
    ///
    /// - Parameters:
    ///   - channel: The chanel name.
    ///   - messageHandler: The channel specific handler which will be called with each message received from this channel.    
    ///   - completion: The closure called when the `subscribe` is complete.
    public func subscribe(channel: String, messageHandler: ((PubSubMessage) -> ())?, completion: @escaping (PubSubOutcome) -> ()) {
        
        let seq = incrementSequence()
        
        if let msgHandler = messageHandler {
            channelHandlers[channel] = msgHandler
        }
        
        func completionHandler(response: PubSubResponse?, error: PubSubErrorResponse?) -> (){
            if let err = error {
                channelHandlers.removeValue(forKey: channel)
                completion(PubSubOutcome.pubSubResponseError(err))
            } else {
                if let result = response {
                    completion(PubSubOutcome.pubSubSuccess(result.channels as Any))
                }
            }
        }
        
        handlerDispatcher.setObject(Handler(completionHandler), forKey: seq)
        
        let params: [String: Any] = [
            "seq": sequence,
            "action": "subscribe",
            "channel": channel
        ]

        writeToSocket(params: params)
    }
    
    /// Unsubscribes from a channel.
    ///
    /// The successful result contains an array with currently subscribed channels without the channel just unsubscribed from. The connection needs read permission in order to unsubscribe from the channel.
    ///
    /// - Parameters:
    ///   - channel: The name of the channel to unsubscribe from.
    ///   - completion: The closure called when the `unsubscribe` is complete.
    public func unsubscribe(channel: String, completion: @escaping (PubSubOutcome) -> ()) {
        
        let seq = incrementSequence()
        
        func completionHandler(response: PubSubResponse?, error: PubSubErrorResponse?) -> (){
            if let err = error {
                completion(PubSubOutcome.pubSubResponseError(err))
            } else {
                if let result = response {
                    channelHandlers.removeValue(forKey: channel)
                    completion(PubSubOutcome.pubSubSuccess(result.channels as Any))
                }
            }
        }
        
        handlerDispatcher.setObject(Handler(completionHandler), forKey: seq)

        let params: [String: Any] = [
            "seq": sequence,
            "action": "unsubscribe",
            "channel": channel
        ]

        writeToSocket(params: params)
    }
    
    /// Unsubscribes from all channels
    ///
    /// The successful result should be an empty array. The connection needs read permission in order to unsubscribe from all channels.
    ///
    /// - Parameter completion: The closure called when the `unsubscribeAll` is complete.
    public func unsubscribeAll(completion: @escaping (PubSubOutcome) -> ()) {
        
        let seq = incrementSequence()
        
        func completionHandler(response: PubSubResponse?, error: PubSubErrorResponse?) -> (){
            if let err = error {
                completion(PubSubOutcome.pubSubResponseError(err))
            } else {
                if let result = response {
                    channelHandlers.removeAll()
                    completion(PubSubOutcome.pubSubSuccess(result.channels as Any))
                }
            }
        }
        
        handlerDispatcher.setObject(Handler(completionHandler), forKey: seq)

        let params: [String: Any] = [
            "seq": sequence,
            "action": "unsubscribe-all"
        ]

        writeToSocket(params: params)
    }
    
    /// Gets all subscriptions.
    ///
    /// The successful result contains an array with currently subscribed channels.
    ///
    /// - Parameter completion: The closure called when the `listSubscriptions` is complete.
    public func listSubscriptions(completion: @escaping (PubSubOutcome) -> ()) {
        
        let seq = incrementSequence()
        
        func completionHandler(response: PubSubResponse?, error: PubSubErrorResponse?) -> (){
            if let err = error {
                completion(PubSubOutcome.pubSubResponseError(err))
            } else {
                if let result = response {
                    completion(PubSubOutcome.pubSubSuccess(result.channels as Any))
                }
            }
        }
        
        handlerDispatcher.setObject(Handler(completionHandler), forKey: seq)
        
        let params: [String: Any] = [
            "seq": sequence,
            "action": "subscriptions"
        ]

        writeToSocket(params: params)
    }
    
    /// Publishes a message to a channel. 
    /// 
    /// The connection must have write permissions to successfully publish a message. The message string is limited to 64KiB. Messages that exceed this limit will result in the termination of the websocket connection.
    ///
    /// - Parameters:
    ///   - channel: The channel where message will be published.
    ///   - message: The message to publish.
    ///   - errorHandler: The closure called when an error occured.
    public func publish(channel: String, message: String, errorHandler: @escaping (PubSubErrorResponse?) -> ()) {

        let seq = incrementSequence()
        handlerDispatcher.setObject(Handler(errorHandler), forKey: seq)
        
        let params: [String: Any] = [
            "seq": sequence,
            "action": "pub",
            "chan": channel,
            "msg": message
        ]

        writeToSocket(params: params)
    }

    /// Publishes a message to a channel with acknowledgement. 
    ///
    /// The connection must have write permissions to successfully publish a message. The message string is limited to 64KiB. Messages that exceed this limit will result in the termination of the websocket connection.
    ///
    /// - Parameters:
    ///   - channel: The channel where message will be published.
    ///   - message: The message to publish.
    ///   - completion: The closure called when the `publishWithAck` is complete.
    public func publishWithAck(channel: String, message: String, completion: @escaping (PubSubOutcome) -> ()) {
        
        let seq = incrementSequence()
        
        func completionHandler(response: PubSubResponse?, error: PubSubErrorResponse?) -> (){
            if let err = error {
                completion(PubSubOutcome.pubSubResponseError(err))
            } else {
                if let result = response {
                    completion(PubSubOutcome.pubSubSuccess(result.messageUUID as Any))
                }
            }
        }
        
        handlerDispatcher.setObject(Handler(completionHandler), forKey: seq)
        
        let params: [String: Any] = [
            "seq": sequence,
            "action": "pub",
            "chan": channel,
            "msg": message,
            "ack": true
        ]
        
        writeToSocket(params: params)
    }
    
    private func incrementSequence() -> Int {
        lock.wait()
        defer { lock.signal() }
        sequence += 1
        return sequence
    }

    private func writeToSocket(params: [String: Any]) {
        guard webSocket.isConnected else {
            self.onError?(NSError(domain: WebSocket.ErrorDomain, code: Int(100), userInfo: [NSLocalizedDescriptionKey: "Web socket is disconnected"]))
            return
        }
        
        do {
            let data: Data = try JSONSerialization.data(withJSONObject: params, options: .init(rawValue: 0))
            webSocket.write(data: data)
        } catch {
            self.onError?(error)
        }
    }
    
    @objc private func reconnect() {
        self.connect(sessionUUID: self.sessionUUID)
    }
}
