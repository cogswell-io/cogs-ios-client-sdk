//
//  GambitResponse.swift
//  GambitSDK
//

/**
 * Copyright (C) 2016 Aviata Inc. All Rights Reserved.
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

public typealias JSON = AnyObject

public protocol GambitResponse {
  init(json: JSON) throws
}

public class GambitResponseMessage: GambitResponse {
  public private(set) var message: String = ""
  
  public required init(json: JSON) throws {
    guard let msg = json["message"] as? String else {
      throw NSError(domain: "GambitSDKError - ResponseMessage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
    }
    
    self.message = msg
  }
}

public class GambitMessageResponse: GambitResponse, CustomStringConvertible {
  public let namespace: String
  public let campaignID: Int
  public let campaignName: String
  public let ciidHash: String
  public let eventName: String
  public let messageID: String
  public var forwardedEvent: [String: AnyObject]?
  public var notificationMsg: String?
  
  public var accessKey: String?
  public var clientSalt: String?
  public var timestamp: String?
  public var debugDirective: String?
  public var attributes: [String: AnyObject]?
  
  public required init(json: JSON) throws {
    guard let msg = json["message"] as? String else {
      throw NSError(domain: "GambitSDKError - ResponseMessage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
    }
    let j = try NSJSONSerialization.JSONObjectWithData(msg.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments)
    
    guard let namespace = j["namespace"] as? String else {
      throw NSError(domain: "GambitSDKError - ResponseMessage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
    }
    guard let campaignID = j["campaign_id"] as? Int else {
      throw NSError(domain: "GambitSDKError - ResponseMessage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
    }
    guard let campaignName = j["campaign_name"] as? String else {
      throw NSError(domain: "GambitSDKError - ResponseMessage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
    }
    guard let ciidHash = j["ciid_hash"] as? String else {
      throw NSError(domain: "GambitSDKError - ResponseMessage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
    }
    guard let eventName = j["event_name"] as? String else {
      throw NSError(domain: "GambitSDKError - ResponseMessage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
    }
    guard let messageID = j["message_id"] as? String else {
      throw NSError(domain: "GambitSDKError - ResponseMessage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
    }

    self.namespace      = namespace
    self.campaignID     = campaignID
    self.campaignName   = campaignName
    self.ciidHash       = ciidHash
    self.eventName      = eventName
    self.messageID      = messageID
    self.forwardedEvent = j["forwarded_event"] as? [String: AnyObject]
    self.notificationMsg = j["notification_message"] as? String
    
    if let dataString = j["data"] as? String {
      let d = try NSJSONSerialization.JSONObjectWithData(dataString.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments)
      
      self.accessKey      = d["access_key"] as? String
      self.clientSalt     = d["client_salt"] as? String
      self.timestamp      = d["timestamp"] as? String
      self.debugDirective = d["debug_directive"] as? String
      self.attributes     = d["attributes"] as? [String: AnyObject]
    }
  }
  
  public var description: String {
    var s = ""
    
    s += "namespace: \(self.namespace)\n"
    s += "campaign_id: \(self.campaignID)\n"
    s += "campaign_name: \(self.campaignName)\n"
    s += "ciid_hash: \(self.ciidHash)\n"
    s += "event_name: \(self.eventName)\n"
    s += "message_id: \(self.messageID)\n"
    if let forwardedEvent = self.forwardedEvent {
      s += "forwarded_event: \(forwardedEvent)"
    }
    if let notificationMsg = self.notificationMsg {
      s += "notification_message: \(notificationMsg)"
    }
    if let accessKey = self.accessKey {
      s += "access_key: \(accessKey)\n"
    }
    if let clientSalt = self.clientSalt {
      s += "client_salt: \(clientSalt)\n"
    }
    if let timestamp = self.timestamp {
      s += "timestamp: \(timestamp)\n"
    }
    if let debugDirective = self.debugDirective {
      s += "debug_directive: \(debugDirective)\n"
    }
    if let attributes = self.attributes {
      s += "attributes: \(attributes)\n"
    }
    
    return s
  }
}

public typealias GambitResponseEvent = GambitResponseMessage
public typealias GambitResponsePush = GambitResponseMessage
