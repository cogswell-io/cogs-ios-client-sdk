//
//  Request.swift
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

enum RequestMethods {
  case POST
  case DELETE
  case GET
  
  func value() -> String {
    switch self {
    case .POST: return "POST"
    case .DELETE: return "DELETE"
    case .GET: return "GET"
    }
  }
}

struct Request {
  let urlRequest: NSMutableURLRequest
  
  init(urlString: String, method: RequestMethods) {
    let url = NSURL(string: urlString)!
    urlRequest = NSMutableURLRequest(URL: url)
    urlRequest.HTTPMethod = method.value()
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
  }
  
  func setParams(params: [String: AnyObject]) {
    do {
      urlRequest.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: .init(rawValue: 0))
    }
    catch {
      print(error)
    }
  }
  
  func setPayloadHmac(hmac: String) {
    urlRequest.setValue(hmac, forHTTPHeaderField: "Payload-HMAC")
  }
  
  func setPayloadHmacAndJSON(hmac: String, json: String) {
    urlRequest.setValue(json, forHTTPHeaderField: "JSON-Base64")
    urlRequest.setValue(hmac, forHTTPHeaderField: "Payload-HMAC")
  }
  
  func getBody() -> NSString {
    return NSString(data: urlRequest.HTTPBody!, encoding: NSUTF8StringEncoding)!
  }
}
