//
//  PubSubResponse.swift
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

/// JSON Responsible protocol
public protocol PubSubResponsible {
    init(json: JSON) throws
}

/// An enum representing the possible pub/sub actions
///
/// - sessionUuid: Get session id.
/// - subscribe: Subscribe to a channel.
/// - unsubscribe: Unsubscribe from a channel.
/// - unsubscribeAll: Unsubscribe from all channels.
/// - subscriptions: List subscriptions.
/// - publish: Publish message.
/// - message: Message received.
/// - invalidRequest: Invalid request.
public enum PubSubAction: String {
    /// Get session id.
    case sessionUuid    = "session-uuid"
    /// Subscribe to a channel.
    case subscribe      = "subscribe"
    /// Unsubscribe from a channel.
    case unsubscribe    = "unsubscribe"
    /// Unsubscribe from all channels.
    case unsubscribeAll = "unsubscribe-all"
    /// List subscriptions.
    case subscriptions  = "subscriptions"
    /// Publish message.
    case publish        = "pub"
    /// Message received.
    case message        = "msg"
    /// Invalid request.
    case invalidRequest = "invalid-request"
}

/// An enum representing the possible server response codes
///
/// - success: Request completed successfully.
/// - generalError: General error occured.
/// - invalidRequest: Invalid request has been sent(malformed JSON, bad attributes or types, etc.)
/// - unauthorised: There isn't permissions for requested action.
/// - notFound: Subscription not found.
public enum PubSubResponseCode: Int {
    /// The request completed successfully.
    case success = 200
    /// General error occured.
    case generalError = 500
    /// Invalid request has been sent(malformed JSON, bad attributes or types, etc.).
    case invalidRequest = 400
    /// There isn't permissions for requested action.
    case unauthorised = 401
    /// Subscription not found.
    case notFound = 404
}

/// Base pub/sub response wrapping class
open class PubSubResponse: PubSubResponsible, CustomStringConvertible {
    
    /// Response sequence number.
    open let seq: Int
    /// Response action.
    open let action: String
    /// Response code.
    open let code: Int
    /// Session uuid.
    open let uuid: String?
    /// Subscribed channels.
    open let channels: [String]?
    /// Message uuid.
    open let messageUUID: String?

    /// Initializes `PubSubResponse` object with JSON.
    ///
    /// - Parameter json: The received JSON.
    /// - Throws: The error thrown when occures.
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

    /// Response `PubSubAction` action type.
    var actionType: PubSubAction {
        return PubSubAction(rawValue: self.action)!
    }

    /// Response description string.
    open var description: String {
        var s = ""

        s += "seq: \(self.seq)\n"
        s += "action: \(self.action)\n"
        s += "code: \(self.code)"
        
        return s
    }
}

/// Cogs pub/sub message wrapping class
open class PubSubMessage: PubSubResponsible {

    /// Message id.
    open let id: String
    /// Message action.
    open let action: String
    /// Message timestmp.
    open let time: String
    /// The channel message is sent on.
    open let channel: String
    /// The message itself.
    open let message: String

    /// Initializes `PubSubMessage` object with JSON.
    ///
    /// - Parameter json: The received JSON.
    /// - Throws: The error thrown when occures.
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
    }
    
    /// The message description.
    var actionType: PubSubAction {
        return PubSubAction(rawValue: self.action)!
    }
}


/// Invalid format response (malformed JSON, bad attributes or types, etc.)
open class PubSubErrorResponse: PubSubResponsible {

    /// Response action.
    open let action: String
    /// Response code.
    open let code: Int
    /// Response message.
    open let message: String
    /// Response details.
    open let details: String
    /// Response sequence number.
    open let sequence: Int?
    /// Response matching request.
    open let request: [String: Any]?

    /// Initializes `PubSubErrorResponse` object with JSON.
    ///
    /// - Parameter json: The received JSON.
    /// - Throws: The error value thrown when occures.
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
    
    /// Initializes `PubSubErrorResponse` object with code and message during the validation.
    ///
    /// - Parameters:
    ///   - code: The error response code.
    ///   - message: The error message.
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
