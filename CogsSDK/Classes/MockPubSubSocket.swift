
import Foundation

public final class MockPubSubSocket: Socket {

    private var keys: [String]          = []
    private var channels: [String]      = []
    private let unauthMessage: String   = "Not Authorized"
    private let notFoundMessage: String = "Not Found"
    public var isConnected: Bool {
        return true
    }
    public var options: PubSubOptions

    public var onConnect: ((Void) -> Void)?
    public var onDisconnect: ((NSError?) -> Void)?
    public var onText: ((String) -> Void)?
    public var onError: ((Error) -> ())?

    /// Description
    ///
    /// - Parameters:
    ///   - keys: The provided project keys.
    ///   - options: The connection options.
    public init(keys: [String], options: PubSubOptions?) {
        self.keys = keys
        
        if let ops = options {
            self.options           = ops
        } else {
            self.options           = PubSubOptions.defaultOptions
        }
    }

    public func connect(_ sessionUUID: String?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.onConnect?()
        }
    }

    public func disconnect() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.onDisconnect?(nil)
        }
    }

    public func getSessionUUID(_ params: [String: Any]) {
        let response: [String: Any] = [
            "seq": params["seq"] as Any,
            "action": PubSubAction.sessionUuid.rawValue,
            "code": PubSubResponseCode.success.rawValue,
            "uuid": UUID().uuidString.lowercased()
        ]

        sendResponse(response)
    }

    public func subscribe(_ params: [String : Any]) {
        var response: [String: Any] = [:]

        let readKeyIndex = keys.index(where: { $0.contains("R") })

        if readKeyIndex != nil {
            self.channels.append(params["channel"] as! String)

             response = [
                "seq": params["seq"] as Any,
                "action": PubSubAction.subscribe.rawValue,
                "code": PubSubResponseCode.success.rawValue,
                "channels": channels
            ]
        } else {
            response = [
                "seq": params["seq"] as Any,
                "action": PubSubAction.subscribe.rawValue,
                "code": PubSubResponseCode.unauthorised.rawValue,
                "message": unauthMessage,
                "details": "You do not have read permissions on this socket, and therefore cannot subscribe to channels."
            ]
        }

        sendResponse(response)
    }

    public func unsubscribe(_ params: [String : Any]) {
        var response: [String: Any] = [:]

        let readKeyIndex = keys.index(where: { $0.contains("R") })

        if readKeyIndex != nil {
            let channelIndex = channels.map { $0 }.index(of: params["channel"] as! String)
            if let index = channelIndex {
                channels.remove(at: index)

                response = [
                    "seq": params["seq"] as Any,
                    "action": PubSubAction.unsubscribe.rawValue,
                    "code": PubSubResponseCode.success.rawValue,
                    "channels": channels
                ]
            } else {
                response = [
                    "seq": params["seq"] as Any,
                    "action": PubSubAction.unsubscribe.rawValue,
                    "code": PubSubResponseCode.notFound.rawValue,
                    "message": notFoundMessage,
                    "details": "You are not subscribed to the specified channel."
                ]
            }


        } else {
            response = [
                "seq": params["seq"] as Any,
                "action": PubSubAction.unsubscribe.rawValue,
                "code": PubSubResponseCode.unauthorised.rawValue,
                "message": unauthMessage,
                "details": "You do not have read permissions on this socket. You have been unsubscribed from all channels."
            ]
        }

        sendResponse(response)
    }

    public func unsubscribeAll(_ params: [String : Any]) {
        var response: [String: Any] = [:]

        let readKeyIndex = keys.index(where: { $0.contains("R") })

        if readKeyIndex != nil {
            response = [
                "seq": params["seq"] as Any,
                "action": PubSubAction.unsubscribeAll.rawValue,
                "code": PubSubResponseCode.success.rawValue,
                "channels": channels
            ]

            channels.removeAll()
        } else {
            response = [
                "seq": params["seq"] as Any,
                "action": PubSubAction.unsubscribeAll.rawValue,
                "code": PubSubResponseCode.unauthorised.rawValue,
                "message": unauthMessage,
                "details": "You do not have read permissions on this socket. You have been unsubscribed from all channels."
            ]
        }

        sendResponse(response)
    }

    public func listSubscriptions(_ params: [String : Any]) {
        var response: [String: Any] = [:]

        let readKeyIndex = keys.index(where: { $0.contains("R") })

        if readKeyIndex != nil {
            response = [
                "seq": params["seq"] as Any,
                "action": PubSubAction.subscriptions.rawValue,
                "code": PubSubResponseCode.success.rawValue,
                "channels": channels
            ]
        } else {
            response = [
                "seq": params["seq"] as Any,
                "action": PubSubAction.subscriptions.rawValue,
                "code": PubSubResponseCode.unauthorised.rawValue,
                "message": unauthMessage,
                "details": "You do not have read permissions on this socket, and therefore cannot list subscriptions."
            ]
        }

        sendResponse(response)
    }

    public func publish(_ params: [String : Any]) {
        var response: [String: Any] = [:]

        let writeKeyIndex = keys.index(where: { $0.contains("W") })

        if writeKeyIndex != nil {
             response = [
                "id": UUID().uuidString.lowercased(),
                "action": PubSubAction.message.rawValue,
                "time": Date().toISO8601,
                "chan": params["chan"] as Any,
                "msg": params["msg"] as Any
            ]
        } else {
            response = [
                "seq": params["seq"] as Any,
                "action": PubSubAction.publish.rawValue,
                "code": PubSubResponseCode.unauthorised.rawValue,
                "message": unauthMessage,
                "details": "You do not have write permissions on this socket, and therefore cannot publish to channels."
            ]
        }

        sendResponse(response)
    }

    public func publishWithAck(_ params: [String : Any]) {
        var response: [String: Any] = [:]

        let writeKeyIndex = keys.index(where: { $0.contains("W") })

        if writeKeyIndex != nil {
            let messageID = UUID().uuidString.lowercased()
            response = [
                "seq": params["seq"] as Any,
                "action": PubSubAction.publish.rawValue,
                "code": PubSubResponseCode.success.rawValue,
                "id": messageID
            ]

            let message: [String: Any] = [
                "id": messageID,
                "action": PubSubAction.message.rawValue,
                "time": Date().toISO8601,
                "chan": params["chan"] as Any,
                "msg": params["msg"] as Any
            ]

            sendResponse(message)
        } else {
            response = [
                "seq": params["seq"] as Any,
                "action": PubSubAction.publish.rawValue,
                "code": PubSubResponseCode.unauthorised.rawValue,
                "message": unauthMessage,
                "details": "You do not have write permissions on this socket, and therefore cannot publish to channels."
            ]
        }

        sendResponse(response)
    }

    private func sendResponse(_ response: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: response, options: .init(rawValue: 0))

            let stringResponse = String(NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)!)

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) { 
                self.onText?(stringResponse)
            }
        } catch {
            self.onError?(error)
        }
    }
}
