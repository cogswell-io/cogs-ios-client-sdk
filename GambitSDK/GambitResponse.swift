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

public typealias GambitResponseEvent = GambitResponseMessage
public typealias GambitResponsePush = GambitResponseMessage
