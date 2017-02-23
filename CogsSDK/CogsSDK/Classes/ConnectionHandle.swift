
import Foundation
import Starscream

public class ConnectionHandle {
   
    private let defaultReconnectDelay: Int = 5000
    
    private var webSocket : WebSocket
    private var options: PubSubOptions
    private var keys: [String]!
    private var sessionUUID: String?
    private var sequence: Int = 0
    
    public var onNewSession: ((String) -> ())?
    public var onReconnect: (() -> ())?
    public var onClose: ((Error?) -> ())?
    public var onError: ((Error) -> ())?
    public var onErrorResponse: ((PubSubErrorResponse) -> ())?
    public var onMessage: ((PubSubMessage) -> ())?
    public var onRawRecord: ((RawRecord) -> ())?
    
    public init(keys: [String], options: PubSubOptions) {
        
        self.keys    = keys
        self.options = options
        
        webSocket = WebSocket(url: URL(string: self.options.url)!)
        webSocket.timeout = self.options.connectionTimeout
        
        webSocket.onConnect = {
            self.getSessionUuid()
        }
        
        webSocket.onDisconnect = { (error: NSError?) in
//<<<<<<< HEAD
//            self.onClose?(error)
//=======
//            
//            if (error != nil) {
//                self.onError?(error)
//            }
//            else {
//               self.onClose?()
//            }
//>>>>>>> c57d02cf0e3f816d1b6d2ee50f8aa9c74216931b

            if self.options.autoReconnect {
                self.connect(sessionUUID: self.sessionUUID)
            }
        }

        webSocket.onText = { (text: String) in
            DialectValidator.parseAndAutoValidate(record: text, completionHandler: { (object, error, responseError) in
                if let error = error {
                    self.onError?(error)
                } else if let respError = responseError {
                    self.onErrorResponse?(respError)
                } else if let obj = object {
                    if let message = object as? PubSubMessage {
                        self.onMessage?(message)
                    } else if let sessionUUID = object as? PubSubResponseUUID {
                        if sessionUUID.uuid == self.sessionUUID {
                            self.onReconnect?()
                        } else {
                            self.onNewSession?(sessionUUID.uuid)
                        }

                        self.sessionUUID = sessionUUID.uuid
                    } else {
                        self.onRawRecord?(text)
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
        }
    }
    
    /// Getting session UUID
    public func getSessionUuid() {
        sequence += 1
        let params: [String: Any] = [
            "seq": sequence ,
            "action": "session-uuid"
        ]

        writeToSocket(params: params)
    }
    
    /// Subscribing to a channel
    ///
    /// - Parameter channelName: the name of the channel to subscribe
    public func subscribe(channelName: String) {
        sequence += 1
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
    public func unsubsribe(channelName: String) {
        sequence += 1

        let params: [String: Any] = [
            "seq": sequence,
            "action": "unsubscribe",
            "channel": channelName
        ]

        writeToSocket(params: params)
    }
    
    /// Unsubscribing from all channels
    public func unsubscribeAll() {
        sequence += 1
        let params: [String: Any] = [
            "seq": sequence,
            "action": "unsubscribe-all"
        ]

        writeToSocket(params: params)
    }
    
    /// Gets all subscriptions
    public func listSubscriptions() {
        sequence += 1
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
    public func publish(channelName: String, message: String, acknowledgement: Bool? = false) {
        sequence += 1
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
    public func publishWithAck(channelName: String, message: String) {
        self.publish(channelName: channelName, message: message, acknowledgement: true)
    }
    
    private func writeToSocket(params: [String: Any]) {
        guard webSocket.isConnected else {
            assertionFailure("Web socket is disconnected")
            
            return
        }
        
        do {
            let data: Data = try JSONSerialization.data(withJSONObject: params, options: .init(rawValue: 0))
            webSocket.write(data: data) { _ in
                self.sequence = params["seq"] as! Int
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    private func parseResponse(_ response: String) -> JSON? {
        do {
            let json = try JSONSerialization.jsonObject(with: response.data(using: String.Encoding.utf8)!, options: .allowFragments) as JSON
            
            return json
        } catch {
            return nil
        }
    }
}
