
import Foundation
import Starscream
import CryptoSwift

/// Open a connection to the Cogswell Pub/Sub system
public class CogsPubSubService {

    private let defaultReconnectDelay: Int = 5000
    private var options: PubSubOptions
    private var webSocket : WebSocket
    private var keys: [String]!
    private var sessionUUID: String?
    private var sequence: Int = 0
    
    public var onNewSession: (() -> ())!
    public var onReconnect: (() -> ())!
    public var onDisconnect: (() -> ())!

    public init(options: PubSubOptions) {

        //self.options = options ?? PubSubOptions.defaultOptions
        self.options = options
        
        webSocket = WebSocket(url: URL(string: self.options.url)!)
        webSocket.timeout = self.options.connectionTimeout

        webSocket.onConnect = {

            self.getSessionUuid(completion: { json in
                do {
                    let id = try PubSubResponseUUID(json: json).uuid

                    if id == self.sessionUUID {
                        self.onReconnect()
                    } else {
                        self.onNewSession()
                    }

                    self.sessionUUID = id
                } catch {

                }
            })
        }

        webSocket.onDisconnect = { (error: NSError?) in
            self.onDisconnect()

            if self.options.autoReconnect {
                self.connect(keys: self.keys, sessionUUID: self.sessionUUID)
            }
        }
    }

    /// Provides connection with the websocket
    ///
    /// - Parameters:
    ///   - keys: the provided project keys
    ///   - sessionUUID: if supplied client session will be restored
    public func connect(keys: [String], sessionUUID: String?) {
        self.keys        = keys
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
    ///
    /// - Parameter completion: completion handler with theJ SON response
    public func getSessionUuid(completion: @escaping ((JSON) -> ())) {
        let params: [String: Any] = [
            "seq": sequence + 1,
            "action": "session-uuid"
        ]

        webSocket.onText = { (text: String) in
            completion(self.parseResponse(text)!)
        }

        writeToSocket(params: params)
    }

    /// Subscribing to a channel
    ///
    /// - Parameters:
    ///   - channelName: the name of the channel to subscribe
    ///   - completion: completion handler with the JSON response
    public func subscribe(channelName: String, completion: @escaping ((JSON) -> ())) {
        let params: [String: Any] = [
            "seq": sequence + 1,
            "action": "subscribe",
            "channel": channelName
        ]

        webSocket.onText = { (text: String) in
            completion(self.parseResponse(text)!)
        }

        writeToSocket(params: params)
    }

    /// Unsubscribing from a channel
    ///
    /// - Parameters:
    ///   - channelName: the name of the channel to unsubscribe from
    ///   - completion: completion handler with the JSON response
    public func unsubsribe(channelName: String, completion: @escaping ((JSON) -> ())) {
        let params: [String: Any] = [
            "seq": sequence + 1,
            "action": "unsubscribe",
            "channel": channelName
        ]

        webSocket.onText = { (text: String) in
            completion(self.parseResponse(text)!)
        }

        writeToSocket(params: params)
    }

    /// Unsubscribing from all channels
    ///
    /// - Parameter completion: completion handler with the JSON response
    public func unsubscribeAll(completion: @escaping ((JSON) -> ())) {
        let params: [String: Any] = [
            "seq": sequence + 1,
            "action": "unsubscribe-all"
        ]

        webSocket.onText = { (text: String) in
            completion(self.parseResponse(text)!)
        }

        writeToSocket(params: params)
    }

    /// Gets all subscriptions
    ///
    /// - Parameter completion: completion handler with the JSON response
    public func listSubscriptions(completion: @escaping ((JSON) -> ())) {
        let params: [String: Any] = [
            "seq": sequence + 1,
            "action": "subscriptions"
        ]

        webSocket.onText = { (text: String) in
            completion(self.parseResponse(text)!)
        }

        writeToSocket(params: params)
    }

    /// Publishing a message to a channel
    ///
    /// - Parameters:
    ///   - channelName: the channel where message will be published
    ///   - message: the message to publish
    ///   - acknowledgement: acknowledgement for the published message
    ///   - completion: completion handler with the JSON response
    public func publish(channelName: String, message: String, acknowledgement: Bool? = false, completion: @escaping ((JSON) -> ())) {
        let params: [String: Any] = [
            "seq": sequence + 1,
            "action": "pub",
            "chan": channelName,
            "msg": message,
            "ack": acknowledgement
        ]

        webSocket.onText = { (text: String) in
             completion(self.parseResponse(text)!)
        }

        writeToSocket(params: params)
    }

    public func publishWithAck(channelName: String, message: String, completion: @escaping ((JSON) -> ())) {
        self.publish(channelName: channelName, message: message, acknowledgement: true) { json in
            completion(json)
        }
    }

    private func writeToSocket(params: [String: Any]) {
        guard webSocket.isConnected else {
            assertionFailure("Web socket is disconnected")

            return
        }

        do {
            let data: Data = try JSONSerialization.data(withJSONObject: params, options: .init(rawValue: 0))
            webSocket.write(data: data)
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

