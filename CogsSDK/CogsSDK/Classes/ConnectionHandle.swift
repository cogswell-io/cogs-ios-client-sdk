
import Foundation
import Starscream

public class ConnectionHandle {
   
    private let defaultReconnectDelay: Double = 5
    
    private var webSocket : WebSocket
    private var options: PubSubOptions
    private var keys: [String]!
    private var sessionUUID: String?
    private var sequence: Int = 0
    
    private var handlerDispatcher = HandlersCache()
    private var callbackQueue = DispatchQueue.main
    
    public var onNewSession: ((String) -> ())?
    public var onReconnect: (() -> ())?
    public var onClose: ((Error?) -> ())?
    public var onError: ((Error) -> ())?
    public var onErrorResponse: ((PubSubResponseError) -> ())?
    public var onMessage: ((PubSubMessage) -> ())?
    public var onRawRecord: ((RawRecord) -> ())?
    
    
    public init(keys: [String], options: PubSubOptions) {
        
        self.keys    = keys
        self.options = options
        
        webSocket = WebSocket(url: URL(string: self.options.url)!)
        webSocket.timeout = self.options.connectionTimeout
        
        webSocket.onConnect = {
            self.getSessionUuid{ _,_ in }
        }
        
        webSocket.onDisconnect = { (error: NSError?) in
            if let err = error, err.code != 1000 {
                self.onClose?(error)
            } else {
                self.onClose?(nil)
            }

            if self.options.autoReconnect {
                Timer.scheduledTimer(timeInterval: self.defaultReconnectDelay, target: self, selector: #selector(self.reconnect(_:)), userInfo: nil, repeats: false)
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
                        let sessionUUID = try PubSubResponseUUID(json: j)

                        if sessionUUID.uuid == self.sessionUUID {
                            self.onReconnect?()
                            //self.onRawRecord?(text)
                        } else {
                            self.onNewSession?(sessionUUID.uuid)
                        }

                        self.sessionUUID = sessionUUID.uuid
                    } catch {
                        do {
                            let message = try PubSubMessage(json: j) 
                            self.onMessage?(message)
                        } catch {
                            //self.onRawRecord?(text)
                        }
                    }
                }
                
                //call method's completion handler
                self.callbackQueue.async { [weak self] in
                    guard let weakSelf = self else { return }
                    
                    if let seq = json?["seq"] as? Int , let completion = weakSelf.handlerDispatcher.object(forKey: seq as! Int),
                        let closure = completion.closure {
                            closure(json, responseError)
                            weakSelf.handlerDispatcher.removeObject(forKey: seq as! Int)
                    }
                }
            })
        }
    }
    
    /// Provides connection with the websocket
    ///
    /// - Parameters:
    ///   - keys: provided project keys in the following order [readKey, writeKey, adminKey]
    ///   - sessionUUID: when supplied client session will be restored if possible
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
    public func getSessionUuid(completion: @escaping CompletionHandler) {
        let seq = sequence + 1
        sequence = seq
        
        handlerDispatcher.setObject(Handler(completion), forKey: seq)
        
        let params: [String: Any] = [
            "seq": seq ,
            "action": "session-uuid"
        ]

        writeToSocket(params: params)
    }
    
    /// Subscribing to a channel
    ///
    /// - Parameter channelName: the name of the channel to subscribe
    public func subscribe(channelName: String, completion: @escaping CompletionHandler) {
        let seq = sequence + 1
        sequence = seq
        
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
    /// - Parameter channelName: the name of the channel to unsubscribe from
    public func unsubsribe(channelName: String, completion: @escaping CompletionHandler) {
        let seq = sequence + 1
        sequence = seq
        
        handlerDispatcher.setObject(Handler(completion), forKey: seq)

        let params: [String: Any] = [
            "seq": sequence,
            "action": "unsubscribe",
            "channel": channelName
        ]

        writeToSocket(params: params)
    }
    
    /// Unsubscribing from all channels
    public func unsubscribeAll(completion: @escaping CompletionHandler) {
        let seq = sequence + 1
        sequence = seq
        
        handlerDispatcher.setObject(Handler(completion), forKey: seq)

        let params: [String: Any] = [
            "seq": sequence,
            "action": "unsubscribe-all"
        ]

        writeToSocket(params: params)
    }
    
    /// Gets all subscriptions
    public func listSubscriptions(completion: @escaping CompletionHandler) {
        let seq = sequence + 1
        sequence = seq
        
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
    ///   - channelName: the channel where message will be published
    ///   - message: the message to publish
    ///   - acknowledgement: acknowledgement for the published message
    public func publish(channelName: String, message: String, acknowledgement: Bool = false, completion: @escaping CompletionHandler) {
        let seq = sequence + 1
        sequence = seq
        
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
    ///   - channelName: the channel where message will be published
    ///   - message: the message to publish
    public func publishWithAck(channelName: String, message: String, completion: @escaping CompletionHandler) {
        
        self.publish(channelName: channelName, message: message, acknowledgement: true) {json, error in
            completion(json, error)
        }
    }
    
    private func writeToSocket(params: [String: Any]) {
        guard webSocket.isConnected else {
            self.onError?(NSError(domain: WebSocket.ErrorDomain, code: Int(100), userInfo: [NSLocalizedDescriptionKey: "Web socket is disconnected"]))
            //assertionFailure("Web socket is disconnected")
            return
        }
        
        do {
            let data: Data = try JSONSerialization.data(withJSONObject: params, options: .init(rawValue: 0))
            webSocket.write(data: data)
        } catch {
            self.onError?(error)
            //assertionFailure(error.localizedDescription)
        }
    }
    
    @objc private func reconnect(_ timer: Timer) {
        self.connect(sessionUUID: self.sessionUUID)
    }
}
