
import Foundation
import Starscream

public class ConnectionHandle {
   
    private let defaultReconnectDelay: Double = 5.0
    private let maxReconnectDelay: Double = 120.0

    private var autoReconnectDelay: Double!
    
    private var webSocket : WebSocket
    private var options: PubSubOptions
    private var keys: [String]!
    private var sessionUUID: String?
    private var sequence: Int = 0
    
    private let lock = DispatchSemaphore(value: 1)
    private var handlerDispatcher = HandlersCache()
    private var callbackQueue = DispatchQueue.main
    
    public var onNewSession: ((String) -> ())?
    public var onReconnect: (() -> ())?
    public var onClose: ((Error?) -> ())?
    public var onError: ((Error) -> ())?
    public var onErrorResponse: ((PubSubErrorResponse) -> ())?
    public var onMessage: ((PubSubMessage) -> ())?
    public var onRawRecord: ((RawRecord) -> ())?
    
    
    public init(keys: [String], options: PubSubOptions) {
        
        self.keys               = keys
        self.options            = options
        self.autoReconnectDelay = defaultReconnectDelay

        webSocket = WebSocket(url: URL(string: self.options.url)!)
        webSocket.timeout = self.options.connectionTimeout
        
        webSocket.onConnect = {
            self.autoReconnectDelay = self.defaultReconnectDelay
            self.getSessionUuid{ _,_ in }
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
            
            DialectValidator.parseAndAutoValidate(record: text, completionHandler: { (json, error, responseError) in
                if let error = error {
                    self.onError?(error)
                } else if let respError = responseError {
                    self.onErrorResponse?(respError)
                } else if let j = json {
                    do {
                        let response = try PubSubResponse(json: j)
   
                        // call method's completion handler
                        self.callbackQueue.async { [weak self] in
                            guard let weakSelf = self else { return }

                            if let completion = weakSelf.handlerDispatcher.object(forKey: response.seq),
                                let closure = completion.closure {
                                completion.completed = true
                                closure(json, responseError)
                                weakSelf.handlerDispatcher.removeObject(forKey: response.seq)
                            }
                        }

                        if let sessionUUID = response.uuid {
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
                            self.onMessage?(message)
                        } catch {
                            self.onError?(error)
                        }
                    }
                }
            })
        }
        
        handlerDispatcher.dispose = { handler, sequence in
            if (handler.completed != true){
                if let closure = handler.closure {
                    closure(nil, PubSubErrorResponse(code: Int(101), message: "Timeout awaiting response to sequence \(sequence)"))
                }
                
                let error = NSError(domain: "CogsSDKError - Timeout", code: Int(101), userInfo: [NSLocalizedDescriptionKey: "Timeout awaiting response to sequence \(sequence)"])
                self.onError?(error)
            }
        }
    }
    
    /// Provides connection with the websocket
    ///
    /// - Parameter sessionUUID: when supplied client session will be restored if possible
    public func connect(sessionUUID: String?) {
        
        self.sessionUUID = sessionUUID
        
        let headers = SocketAuthentication.authenticate(keys: keys, sessionUUID: self.sessionUUID)
        
        webSocket.headers["Payload"] = headers.payloadBase64
        webSocket.headers["PayloadHMAC"] = headers.payloadHmac
        
        webSocket.connect()
    }
    
    ///  Disconnect from the websocket
    public func close() {
        if webSocket.isConnected {
            webSocket.disconnect()
            handlerDispatcher.removeAllObjects()
        }
    }
    
    /// Getting session UUID
    ///
    /// - Parameter completion: The completion handler that returns the response or an error
    public func getSessionUuid(completion: @escaping CompletionHandler) {
        
        let seq = incrementSequence()
        handlerDispatcher.setObject(Handler(completion), forKey: seq)
        
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
    ///   - completion: The completion handler that returns the response or an error.
    public func subscribe(channelName: String, completion: @escaping CompletionHandler) {
        
        let seq = incrementSequence()
        handlerDispatcher.setObject(Handler(completion), forKey: seq)

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
    ///   - completion: The completion handler that returns the response or an error.
    public func unsubsribe(channelName: String, completion: @escaping CompletionHandler) {
        
        let seq = incrementSequence()
        handlerDispatcher.setObject(Handler(completion), forKey: seq)

        let params: [String: Any] = [
            "seq": sequence,
            "action": "unsubscribe",
            "channel": channelName
        ]

        writeToSocket(params: params)
    }
    
    /// Unsubscribing from all channels
    ///
    /// - Parameter completion: The completion handler that returns the response or an error.
    public func unsubscribeAll(completion: @escaping CompletionHandler) {
        
        let seq = incrementSequence()
        handlerDispatcher.setObject(Handler(completion), forKey: seq)

        let params: [String: Any] = [
            "seq": sequence,
            "action": "unsubscribe-all"
        ]

        writeToSocket(params: params)
    }
    
    /// Gets all subscriptions
    ///
    /// - Parameter completion: The completion handler that returns the response or an error.
    public func listSubscriptions(completion: @escaping CompletionHandler) {
        
        let seq = incrementSequence()
        handlerDispatcher.setObject(Handler(completion), forKey: seq)
        
        let params: [String: Any] = [
            "seq": sequence,
            "action": "subscriptions"
        ]

        writeToSocket(params: params)
    }
    
    /// Publishing a message to a channel
    ///
    /// - Parameters:
    ///   - channelName: The channel where message will be published.
    ///   - message: The message to publish.
    ///   - acknowledgement: Acknowledgement for the published message.
    ///   - completion: The completion handler that returns the response or an error.
    public func publish(channelName: String, message: String, acknowledgement: Bool = false, completion: @escaping CompletionHandler) {

        let seq = incrementSequence()
        handlerDispatcher.setObject(Handler(completion), forKey: seq)

        let params: [String: Any] = [
            "seq": sequence,
            "action": "pub",
            "chan": channelName,
            "msg": message,
            "ack": acknowledgement
        ]

        writeToSocket(params: params)
    }

    /// Publishing a message to a channel with acknowledgement
    ///
    /// - Parameters:
    ///   - channelName: The channel where message will be published.
    ///   - message: The message to publish.
    ///   - completion: The completion handler that returns the response or an error.
    public func publishWithAck(channelName: String, message: String, completion: @escaping CompletionHandler) {
        
        self.publish(channelName: channelName, message: message, acknowledgement: true) {json, error in
            completion(json, error)
        }
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
