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

    private var webSocket : Socket
    private var options: PubSubOptions
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
    /// The event is emitted on socket reconnection if it is disconnected for any reason.
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
    /// - Parameter socket: Socket instance
    init(socket: Socket) {

        self.webSocket = socket
        self.options   = socket.options

        self.onNewSession          = self.options.onNewSessionHandler
        self.onReconnect           = self.options.onReconnectHandler
        self.onRawRecord           = self.options.onRawRecordHandler
        self.onMessage             = self.options.onMessageHandler
        self.onClose               = self.options.onCloseHandler
        self.onError               = self.options.onErrorHandler
        self.onErrorResponse       = self.options.onErrorResponseHandler

        self.currentReconnectDelay = socket.options.minReconnectDelay
        self.autoReconnect         = socket.options.autoReconnect

        webSocket.onConnect = { [weak self] in
            guard let weakSelf = self else { return }

            weakSelf.connectHandler?()
            weakSelf.autoReconnect         = weakSelf.options.autoReconnect
            weakSelf.currentReconnectDelay = weakSelf.options.minReconnectDelay
            weakSelf.currentReconnectAtempts = 0
            weakSelf.getSessionUuid { _ in }
        }

        webSocket.onDisconnect = {[weak self] (error: NSError?) in
            guard let weakSelf = self else { return }

            if let err = error, err.code != 1000 {
                weakSelf.onClose?(error)
            } else {
                weakSelf.onClose?(nil)
            }

            func scheduleReconnect() {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + weakSelf.currentReconnectDelay) {
                    weakSelf.reconnect()
                }
            }

            if weakSelf.autoReconnect {
                if weakSelf.options.maxReconnectAttempts > -1 {
                    guard weakSelf.currentReconnectAtempts < weakSelf.options.maxReconnectAttempts else { return }

                    scheduleReconnect()
                    weakSelf.currentReconnectAtempts += 1
                } else {
                    scheduleReconnect()
                }

                print(weakSelf.currentReconnectDelay)
                print(weakSelf.currentReconnectAtempts)

                weakSelf.currentReconnectDelay *= 2.0

                if weakSelf.currentReconnectDelay > weakSelf.options.maxReconnectDelay {
                    weakSelf.currentReconnectDelay = weakSelf.options.maxReconnectDelay
                }
            }
        }

        webSocket.onError = { [weak self] (error: Error) in
            guard let weakSelf = self else { return }

            weakSelf.onError?(error)
        }

        webSocket.onText = {[weak self] (text: String) in
            guard let weakSelf = self else { return }

            weakSelf.onRawRecord?(text)

            DialectValidator.parseAndAutoValidate(record: text) { json, error, responseError in
                var seq: Int?
                var response: PubSubResponse?

                if let error = error {
                    weakSelf.onError?(error)
                } else if let respError = responseError {
                    seq = respError.sequence
                    weakSelf.onErrorResponse?(respError)
                } else if let j = json {
                    do {
                        response = try PubSubResponse(json: j)
                        seq = response?.seq

                        if let sessionUUID = response?.uuid {
                            if sessionUUID == weakSelf.sessionUUID {
                                weakSelf.onReconnect?()
                            } else {
                                weakSelf.onNewSession?(sessionUUID)
                            }

                            weakSelf.sessionUUID = sessionUUID
                        }
                    } catch {
                        do {
                            let message = try PubSubMessage(json: j)
                            weakSelf.channelHandlers[message.channel]?(message)
                            weakSelf.onMessage?(message)
                        } catch {
                            weakSelf.onError?(error)
                        }
                    }
                }

                // call method's completion handler
                weakSelf.callbackQueue.async { [weak self] in
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

        handlerDispatcher.dispose = {[weak self] handler, sequence in
            guard let weakSelf = self else { return }

            if (handler.completed != true && handler.disposable){
                if let closure = handler.closure {
                    closure(nil, PubSubErrorResponse(code: Int(101), message: "Timeout awaiting response to sequence \(sequence)"))
                }

                let error = NSError(domain: "CogsSDKError - Timeout", code: Int(101), userInfo: [NSLocalizedDescriptionKey: "Timeout awaiting response to sequence \(sequence)"])
                weakSelf.onError?(error)
            }
        }

        connect(sessionUUID: nil)
    }

    /// Starts connection with the websocket.
    ///
    /// - Parameter sessionUUID: When supplied client session will be restored if possible.
    private func connect(sessionUUID: String?, completion: (() -> ())? = nil) {

        self.sessionUUID = sessionUUID
        self.connectHandler = completion

        webSocket.connect(sessionUUID)
    }

    /// Drops connection.
    public func dropConnection() {
        if webSocket.isConnected {

            webSocket.disconnect()
            handlerDispatcher.removeAllObjects()
        }
    }

    /// Disconnects from the websocket.
    public func close() {
        if webSocket.isConnected {
            self.autoReconnect = false

            webSocket.disconnect()
            handlerDispatcher.removeAllObjects()
        }
    }

    /// Get session UUID.
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
            "action": PubSubAction.sessionUuid.rawValue
        ]

        webSocket.getSessionUUID(params)
    }

    /// Subscribes to a channel.
    ///
    /// The successful result contains a list of the subscribed channels. The connection needs read permissions in order to subscribe to a channel.
    ///
    /// - Parameters:
    ///   - channel: The channel name.
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
            "action": PubSubAction.subscribe.rawValue,
            "channel": channel
        ]

        webSocket.subscribe(params)
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
            "action": PubSubAction.unsubscribe.rawValue,
            "channel": channel
        ]

        webSocket.unsubscribe(params)
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
            "action": PubSubAction.unsubscribeAll.rawValue
        ]

        webSocket.unsubscribeAll(params)
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
            "action": PubSubAction.subscriptions.rawValue
        ]

        webSocket.listSubscriptions(params)
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
            "action": PubSubAction.publish.rawValue,
            "chan": channel,
            "msg": message
        ]

        webSocket.publish(params)
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
            "action": PubSubAction.publish.rawValue,
            "chan": channel,
            "msg": message,
            "ack": true
        ]

        webSocket.publishWithAck(params)
    }

    private func incrementSequence() -> Int {
        lock.wait()
        defer { lock.signal() }
        sequence += 1
        return sequence
    }
    
    private func reconnect() {
        self.connect(sessionUUID: self.sessionUUID)
    }
}
