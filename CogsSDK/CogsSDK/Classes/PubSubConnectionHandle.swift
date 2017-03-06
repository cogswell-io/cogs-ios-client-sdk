
import Foundation
import Starscream

/// The result of Pub/Sub operation
///
/// - PubSubResponseError: The operation completed with error.
/// - PubSubSuccess: The operation completed successfully with response object.
public enum PubSubOutcome {
    case PubSubResponseError(PubSubErrorResponse)
    case PubSubSuccess(PubSubResponsible)
    //case PubSubError(Error) //It is impossible to get the completion handler when general error occures.
}


//public typealias MessageHandler    =

/// PubSub connection handler
public class PubSubConnectionHandle {
   
    private let defaultReconnectDelay: Double = 5.0
    private let maxReconnectDelay: Double = 150.0

    private var autoReconnectDelay: Double!
    
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
    
    /// New session completion handler
    public var onNewSession: ((String) -> ())?
    
    /// Reconnect completion handler
    public var onReconnect: (() -> ())?
    
    /// A handler for any raw record received from the server, whether a response to a request or a message.
    public var onRawRecord: ((RawRecord) -> ())?
    
    /// Message completion handler
    public var onMessage: ((PubSubMessage) -> ())?

    /// Close completion handler
    public var onClose: ((Error?) -> ())?
    
    /// General error completion handler
    public var onError: ((Error) -> ())?
    
    /// Response error completion handler
    public var onErrorResponse: ((PubSubErrorResponse) -> ())?
    
    
    /// Initializes and returns a connection handler.
    ///
    /// - Parameters:
    ///   - keys: The provided project keys
    ///   - options: The connection options.
    public init(keys: [String], options: PubSubOptions) {
        
        self.keys               = keys
        self.options            = options
        self.autoReconnectDelay = defaultReconnectDelay

        webSocket = WebSocket(url: URL(string: self.options.url)!)
        webSocket.timeout = self.options.connectionTimeout
        
        webSocket.onConnect = {
            self.connectHandler?()
            self.autoReconnectDelay = self.defaultReconnectDelay
            self.getSessionUuid{ _ in }
        }
        
        webSocket.onDisconnect = { (error: NSError?) in
            if let err = error, err.code != 1000 {
                self.onClose?(error)
            } else {
                self.onClose?(nil)
            }

            if self.options.autoReconnect {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + self.autoReconnectDelay) {
                    self.reconnect()
                }

                print(self.autoReconnectDelay)

                let minumumDelay = max(self.defaultReconnectDelay, self.autoReconnectDelay)
                let nextDelay = min(minumumDelay, self.maxReconnectDelay) * 2
                self.autoReconnectDelay = nextDelay
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
    
    /// Creates connection with the websocket.
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
    
    ///  Disconnect from the websocket.
    public func close() {
        if webSocket.isConnected {
            webSocket.disconnect()
            handlerDispatcher.removeAllObjects()
        }
    }
    
    /// Getting session UUID.
    ///
    /// - Parameter completion: The closure called when the `getSessionUuid` is complete.
    public func getSessionUuid(completion: @escaping (PubSubOutcome) -> ()) {
        
        let seq = incrementSequence()
        
        func completionHandler(response: PubSubResponse?, error: PubSubErrorResponse?) -> (){
            if let err = error {
                completion(PubSubOutcome.PubSubResponseError(err))
            } else {
                if let result = response {
                    completion(PubSubOutcome.PubSubSuccess(result))
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
    

    /// Subscribing to a channel
    ///
    /// - Parameters:
    ///   - channelName: The chanel name.
    ///   - messageHandler: The channel specific handler. It is called when a message on this channel comes.
    ///   - completion: The closure called when the `subscribe` is complete.
    public func subscribe(channelName: String, messageHandler: ((PubSubMessage) -> ())?, completion: @escaping (PubSubOutcome) -> ()) {
        
        let seq = incrementSequence()
        
        if let msgHandler = messageHandler {
            channelHandlers[channelName] = msgHandler
        }
        
        func completionHandler(response: PubSubResponse?, error: PubSubErrorResponse?) -> (){
            if let err = error {
                channelHandlers.removeValue(forKey: channelName)
                completion(PubSubOutcome.PubSubResponseError(err))
            } else {
                if let result = response {
                    completion(PubSubOutcome.PubSubSuccess(result))
                }
            }
        }
        
        handlerDispatcher.setObject(Handler(completionHandler), forKey: seq)
        
        let params: [String: Any] = [
            "seq": sequence,
            "action": "subscribe",
            "channel": channelName
        ]

        writeToSocket(params: params)
    }
    
    /// Unsubscribing from a channel
    ///
    /// - Parameters:
    ///   - channelName: The name of the channel to unsubscribe from.
    ///   - completion: The closure called when the `unsubscribe` is complete.
    public func unsubscribe(channelName: String, completion: @escaping (PubSubOutcome) -> ()) {
        
        let seq = incrementSequence()
        
        func completionHandler(response: PubSubResponse?, error: PubSubErrorResponse?) -> (){
            if let err = error {
                completion(PubSubOutcome.PubSubResponseError(err))
            } else {
                if let result = response {
                    channelHandlers.removeValue(forKey: channelName)
                    completion(PubSubOutcome.PubSubSuccess(result))
                }
            }
        }
        
        handlerDispatcher.setObject(Handler(completionHandler), forKey: seq)

        let params: [String: Any] = [
            "seq": sequence,
            "action": "unsubscribe",
            "channel": channelName
        ]

        writeToSocket(params: params)
    }
    
    /// Unsubscribing from all channels
    ///
    /// - Parameter completion: The closure called when the `unsubscribeAll` is complete.
    public func unsubscribeAll(completion: @escaping (PubSubOutcome) -> ()) {
        
        let seq = incrementSequence()
        
        func completionHandler(response: PubSubResponse?, error: PubSubErrorResponse?) -> (){
            if let err = error {
                completion(PubSubOutcome.PubSubResponseError(err))
            } else {
                if let result = response {
                    channelHandlers.removeAll()
                    completion(PubSubOutcome.PubSubSuccess(result))
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
    /// - Parameter completion: The closure called when the `listSubscriptions` is complete.
    public func listSubscriptions(completion: @escaping (PubSubOutcome) -> ()) {
        
        let seq = incrementSequence()
        
        func completionHandler(response: PubSubResponse?, error: PubSubErrorResponse?) -> (){
            if let err = error {
                completion(PubSubOutcome.PubSubResponseError(err))
            } else {
                if let result = response {
                    completion(PubSubOutcome.PubSubSuccess(result))
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
    
    /// Publishing a message to a channel.
    ///
    /// - Parameters:
    ///   - channelName: The channel where message will be published.
    ///   - message: The message to publish.
    ///   - failure: The closure called when an error occured.
    public func publish(channelName: String, message: String, failure: @escaping (PubSubErrorResponse?) -> ()) {

        let seq = incrementSequence()
        handlerDispatcher.setObject(Handler(failure), forKey: seq)
        
        let params: [String: Any] = [
            "seq": sequence,
            "action": "pub",
            "chan": channelName,
            "msg": message
        ]

        writeToSocket(params: params)
    }

    /// Publishing a message to a channel with acknowledgement
    ///
    /// - Parameters:
    ///   - channelName: The channel where message will be published.
    ///   - message: The message to publish.
    ///   - completion: The closure called when the `publishWithAck` is complete.
    public func publishWithAck(channelName: String, message: String, completion: @escaping (PubSubOutcome) -> ()) {
        
        let seq = incrementSequence()
        
        func completionHandler(response: PubSubResponse?, error: PubSubErrorResponse?) -> (){
            if let err = error {
                completion(PubSubOutcome.PubSubResponseError(err))
            } else {
                if let result = response {
                    completion(PubSubOutcome.PubSubSuccess(result))
                }
            }
        }
        
        handlerDispatcher.setObject(Handler(completionHandler), forKey: seq)
        
        let params: [String: Any] = [
            "seq": sequence,
            "action": "pub",
            "chan": channelName,
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
