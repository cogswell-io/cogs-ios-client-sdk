//
//  GambitRequest.swift
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

/// Event Builder Class
public class GambitRequestEvent {
  public let tags: [String]?
  public let debugDirective: String?
  public let accessKey: String
  public let clientSalt: String
  public let clientSecret: String
  public let campaignID: Int?
  public let eventName: String
  public let namespace: String
  public let attributes: [String: AnyObject]
  
  public init(tags: [String]? = nil, debugDirective: String? = nil, accessKey: String, clientSalt: String, clientSecret: String, campaignID: Int? = nil, eventName: String, namespace: String , attributes: [String: AnyObject]) {
    self.tags           = tags
    self.debugDirective = debugDirective
    self.accessKey      = accessKey
    self.clientSalt     = clientSalt
    self.clientSecret   = clientSecret
    self.campaignID     = campaignID
    self.eventName      = eventName
    self.namespace      = namespace
    self.attributes     = attributes
  }
}

/// Register Push Builder Class
public class GambitRequestPush {
  public let clientSalt: String
  public let clientSecret: String
  public let UDID: String
  public let accessKey: String
  public let attributes: [String: AnyObject]
  public let environment: String
  public let platformAppID: String
  let platform: String = "ios"
  public let namespace: String
  
  public init(clientSalt: String, clientSecret: String, UDID: String, accessKey: String, attributes: [String: AnyObject], environment: String, platformAppID: String, namespace: String) {
    self.clientSalt    = clientSalt
    self.clientSecret  = clientSecret
    self.UDID          = UDID
    self.accessKey     = accessKey
    self.attributes    = attributes
    self.environment   = environment
    self.platformAppID = platformAppID
    self.namespace     = namespace
  }
}

/// Message Builder Class
public class GambitRequestMessage {
  public let accessKey: String
  public let clientSalt: String
  public let clientSecret: String
  public let token: String
  public let namespace: String
  public let attributes: [String: AnyObject]
  
  public init(accessKey: String, clientSalt: String, clientSecret: String, token: String, namespace: String, attributes: [String: AnyObject]) {
    self.accessKey = accessKey
    self.clientSalt = clientSalt
    self.clientSecret = clientSecret
    self.token = token
    self.namespace = namespace
    self.attributes = attributes
  }
}











