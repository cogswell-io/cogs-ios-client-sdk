
import Foundation

/// Base cogs pubsub response class
open class PubSubResponse: GambitResponse, CustomStringConvertible {

    open let seq: Int
    open let action: String
    open let code: Int

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

        self.seq    = seq
        self.action = action
        self.code   = code
    }

    open var description: String {
        var s = ""

        s += "seq: \(self.seq)\n"
        s += "action: \(self.action)\n"
        s += "code: \(self.code)"
        
        return s
    }
}

open class PubSubResponseUUID: PubSubResponse {

    open let uuid: String

    public required init(json: JSON) throws {
        guard let uuid = json["uuid"] as? String else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        self.uuid = uuid

        do {
            try super.init(json: json)
        } catch {
            throw error
        }
    }
}

open class PubSubResponseSubscription: PubSubResponse {

    open let channels: [String]

    public required init(json: JSON) throws {
        guard let channels = json["channels"] as? [String] else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        self.channels = channels

        do {
            try super.init(json: json)
        } catch {
            throw error
        }
    }
}

open class PubSubResponsePublishMessage: PubSubResponse {

    open let messageUUID: String

    public required init(json: JSON) throws {
        guard let id = json["id"] as? String else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        self.messageUUID = id

        do {
            try super.init(json: json)
        } catch {
            throw error
        }
    }
}

open class PubSubMessage: GambitResponse {

    open let id: String
    open let time: String
    open let channel: String
    open let message: String

    public required init(json: JSON) throws {
        guard let id = json["id"] as? String else {
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
        self.time    = time
        self.channel = channel
        self.message = message
    }
}


/// Base cogs pubsub error response class
open class PubSubResponseError: GambitResponse {

    open let action: String
    open let code: Int
    open let message: String
    open let details: String

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

        self.action   = action
        self.code     = code
        self.message  = message
        self.details  = details
    }
}

// MARK: General error response
open class PubSubGeneralErrorResponse: PubSubResponseError {

    open let sequence: Int

    public required init(json: JSON) throws {
        guard let seq = json["seq"] as? Int else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        self.sequence = seq

        do {
            try super.init(json: json)
        } catch {
            throw error
        }
    }
}

// Bad request response
open class PubSubBadRequestResponse: PubSubResponseError {

    open let request: [String: Any]

    public required init(json: JSON) throws {

        guard let request = json["bad_request"] as? [String: Any] else {
            throw NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
        }

        self.request = request

        do {
            try super.init(json: json)
        } catch {
            throw error
        }
    }
}

public typealias RawRecord                    = String
