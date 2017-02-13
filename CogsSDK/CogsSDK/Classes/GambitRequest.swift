//
//  GambitRequest.swift
//  GambitSDK
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

/// Event Builder Class
open class GambitRequestEvent {
  open let tags: [String]?
  open let debugDirective: String?
  open let accessKey: String
  open let clientSalt: String
  open let clientSecret: String
  open let campaignID: Int?
  open let eventName: String
  open let namespace: String
  open let attributes: [String: AnyObject]
  
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
open class GambitRequestPush {
  open let clientSalt: String
  open let clientSecret: String
  open let UDID: String
  open let accessKey: String
  open let attributes: [String: AnyObject]
  open let environment: String
  open let applicationID: String
  let platform: String = "ios"
  open let namespace: String
  
  public init(clientSalt: String, clientSecret: String, UDID: String, accessKey: String, attributes: [String: AnyObject], environment: String, applicationID: String, namespace: String) {
    self.clientSalt    = clientSalt
    self.clientSecret  = clientSecret
    self.UDID          = UDID
    self.accessKey     = accessKey
    self.attributes    = attributes
    self.environment   = environment
    self.applicationID = applicationID
    self.namespace     = namespace
  }
}

/// Message Builder Class
open class GambitRequestMessage {
  open let accessKey: String
  open let clientSalt: String
  open let clientSecret: String
  open let token: String
  open let namespace: String
  open let attributes: [String: AnyObject]
  
  public init(accessKey: String, clientSalt: String, clientSecret: String, token: String, namespace: String, attributes: [String: AnyObject]) {
    self.accessKey = accessKey
    self.clientSalt = clientSalt
    self.clientSecret = clientSecret
    self.token = token
    self.namespace = namespace
    self.attributes = attributes
  }
}











