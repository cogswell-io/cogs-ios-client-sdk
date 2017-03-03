
import Foundation

/// JSON Responsible protocol
public protocol PubSubResponsible {
    init(json: JSON) throws
}

public enum PubSubAction: String {
    case sessionUuid    = "session-uuid"
    case subscribe      = "subscribe"
    case unsubscribe    = "unsubscribe"
    case unsubscribeAll = "unsubscribe-all"
    case subscriptions  = "subscriptions"
    case publish        = "pub"
    case message        = "msg"
    case invalidRequest = "invalid-request"
}

public enum PubSubResponseCode: Int {
    case success = 200
    case generalError = 500
    case invalidRequest = 400
    case unauthorised = 401
    case notFound = 404
}

/// Base cogs pubsub response class
open class PubSubResponse: PubSubResponsible, CustomStringConvertible {

    open let seq: Int
    open let action: String
    open let code: Int
    open let uuid: String?
    open let channels: [String]?
    open let messageUUID: String?

    public required init(json: JSON) throws {
        guard let seq = json["seq"] as? Int else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        guard let action = json["action"] as? String else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        guard let code = json["code"] as? Int else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        let uuid     = json["uuid"] as? String
        let channels = json["channels"] as? [String]
        let id       = json["id"] as? String

        self.seq         = seq
        self.action      = action
        self.code        = code
        self.uuid        = uuid
        self.channels    = channels
        self.messageUUID = id
    }

    var actionType: PubSubAction {
        return PubSubAction(rawValue: self.action)!
    }

    open var description: String {
        var s = ""

        s += "seq: \(self.seq)\n"
        s += "action: \(self.action)\n"
        s += "code: \(self.code)"
        
        return s
    }
}

/// Cogs pubsub message response class
open class PubSubMessage: PubSubResponsible {

    open let id: String
    open let action: String
    open let time: String
    open let channel: String
    open let message: String

    public required init(json: JSON) throws {
        guard let id = json["id"] as? String else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        guard let action = json["action"] as? String else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        guard let time = json["time"] as? String else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        guard let channel = json["chan"] as? String else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        guard let message = json["msg"] as? String else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        self.id      = id
        self.action  = action
        self.time    = time
        self.channel = channel
        self.message = message

        var actionType: PubSubAction {
            return PubSubAction(rawValue: self.action)!
        }
    }
}

/// Base cogs pubsub error response class
open class PubSubErrorResponse: PubSubResponsible {

    open let action: String
    open let code: Int
    open let message: String
    open let details: String

    open let sequence: Int?
    open let request: [String: Any]?

    public required init(json: JSON) throws {

        guard let action = json["action"] as? String else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        guard let code = json["code"] as? Int else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        guard let message = json["message"] as? String else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        guard let details = json["details"] as? String else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        let seq = json["seq"] as? Int
        let request = json["bad_request"] as? [String: Any]

        self.action   = action
        self.code     = code
        self.message  = message
        self.details  = details
        self.sequence = seq
        self.request  = request
    }
    
    public init(code: Int, message: String) {
        self.code = code
        self.message = message
        self.action = ""
        self.details = ""
        self.sequence = nil
        self.request = nil
    }
}

public typealias RawRecord                    = String
