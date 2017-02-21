
import Foundation
import Starscream
import CryptoSwift


/// Open a connection to the Cogswell Pub/Sub system
public class CogsPubSubService {

    public static let sharedService = CogsPubSubService()
    public var baseWSURL  : String?
    private var webSocket : WebSocket?
    private var sessionID: Int = 0

    private init() {}

    /// Provides connection with the websocket
    ///
    /// - Parameters:
    ///   - keys: the provided project keys
    ///   - completion: connect completion handler
    public func connect(keys: [String], completion: @escaping (() -> ())) {
        guard let url = baseWSURL else {
            assertionFailure("Please enter WSS URL in CogsPubSubService.sharedService")
            webSocket = nil

            return
        }

        webSocket = WebSocket(url: URL(string: url)!)

        guard let socket = webSocket else { return }

        socket.timeout = 30

        let headers = SocketAuthentication.authenticate(keys: keys)

        socket.headers["Payload"] = headers.payloadBase64
        socket.headers["PayloadHMAC"] = headers.payloadHmac

        socket.onConnect = {
            completion()
        }

        socket.connect()
    }


    ///  Disconnect from the websocket
    ///
    /// - Parameter completion: disconnect completion handler
    public func disconnect(completion: @escaping (() -> ())) {
        guard let socket = webSocket else { return }

        socket.onDisconnect = { (error: NSError?) in
            completion()
        }

        if socket.isConnected {
            socket.disconnect()
        }
    }


    /// Getting session UUID
    ///
    /// - Parameter completion: completion handler with the fetched UUID
    public func getSessionUUID(completion: @escaping ((String) -> ())) {
        let params: [String: Any] = [
            "seq": 1,
            "action": "session-uuid"
        ]

        webSocket?.onText = { (text: String) in
            do {
                let sessionUUID = try PubSubResponseUUID(json: self.parseResponse(text)!)

                completion(sessionUUID.uuid)
            } catch {

            }
        }

        writeToSocket(params: params)
    }

    /// Subscribing to a channel
    ///
    /// - Parameters:
    ///   - channelName: the name of the channel to subscribe
    ///   - completion: completion handler with the list of subscibed channels
    public func subsribeToChannel(channelName: String, completion: @escaping (([String]) -> ())) {
        let params: [String: Any] = [
            "seq": 1,
            "action": "subscribe",
            "channel": channelName
        ]

        webSocket?.onText = { (text: String) in
            do {
                let subscription = try PubSubResponseSubscription(json: self.parseResponse(text)!)

                completion(subscription.channels)
            } catch {

            }
        }

        writeToSocket(params: params)
    }

    /// Unsubscribing from a channel
    ///
    /// - Parameters:
    ///   - channelName: the name of the channel to unsubscribe from
    ///   - completion: completion handler with the list of subscibed channels
    public func unsubsribeFromChannel(channelName: String, completion: @escaping (([String]) -> ())) {
        let params: [String: Any] = [
            "seq": 1,
            "action": "unsubscribe",
            "channel": channelName
        ]

        webSocket?.onText = { (text: String) in
            do {
                let subscription = try PubSubResponseSubscription(json: self.parseResponse(text)!)

                completion(subscription.channels)
            } catch {

            }
        }

        writeToSocket(params: params)
    }

    /// Unsubscribing from all channels
    ///
    /// - Parameter completion: completion handler with the list of previously subscibed channels
    public func unsubsribeFromAllChannels(completion: @escaping (([String]) -> ())) {
        let params: [String: Any] = [
            "seq": 1,
            "action": "unsubscribe-all"
        ]

        webSocket?.onText = { (text: String) in
            do {
                let subscription = try PubSubResponseSubscription(json: self.parseResponse(text)!)

                completion(subscription.channels)
            } catch {

            }
        }

        writeToSocket(params: params)
    }

    /// Gets all subscriptions
    ///
    /// - Parameter completion: completion handler with the list of subscibed channels
    public func getAllSubscriptions(completion: @escaping (([String]) -> ())) {
        let params: [String: Any] = [
            "seq": 1,
            "action": "subscriptions"
        ]

        webSocket?.onText = { (text: String) in
            do {
                let subscription = try PubSubResponseSubscription(json: self.parseResponse(text)!)

                completion(subscription.channels)
            } catch {

            }
        }

        writeToSocket(params: params)
    }

    /// Publishing a message to a channel
    ///
    /// - Parameters:
    ///   - channelName: the channel where message will be published
    ///   - message: the message to publish
    ///   - acknowledgement: acknowledgement for the published message
    ///   - completion: completion handler with the delivered message to subscribers
    public func publishMessage(channelName: String, message: String, acknowledgement: Bool = false, completion: @escaping ((PubSubMessage) -> ())) {
        let params: [String: Any] = [
            "seq": 1,
            "action": "pub",
            "chan": channelName,
            "msg": message,
            "ack": acknowledgement
        ]

        webSocket?.onText = { (text: String) in
            print(text)
            do {
                let message = try PubSubMessage(json: self.parseResponse(text)!)

                completion(message)
            } catch {

            }
        }

        writeToSocket(params: params)
    }
    

    private func writeToSocket(params: [String: Any]) {
        guard let socket = webSocket else { return }
        guard socket.isConnected else {
            assertionFailure("Web socket is disconnected")

            return
        }

        do {
            let data: Data = try JSONSerialization.data(withJSONObject: params, options: .init(rawValue: 0))
            socket.write(data: data)
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

