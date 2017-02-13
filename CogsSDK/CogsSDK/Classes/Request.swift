//
//  Request.swift
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

enum RequestMethods: String {
  case GET    = "GET"
  case POST   = "POST"
  case DELETE = "DELETE"
}

struct Request {
  var urlRequest: URLRequest
  
  init(urlString: String, method: RequestMethods) {
    let url = URL(string: urlString)!
    urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = method.rawValue
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
  }
  
  mutating func setParams(params: [String: AnyObject]) {
    do {
      urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: .init(rawValue: 0))
    }
    catch {
      print(error)
    }
  }
  
  mutating func setPayloadHmac(_ hmac: String) {
    urlRequest.setValue(hmac, forHTTPHeaderField: "Payload-HMAC")
  }
  
  mutating func setPayloadHmacAndJSON(_ hmac: String, json: String) {
    urlRequest.setValue(json, forHTTPHeaderField: "JSON-Base64")
    urlRequest.setValue(hmac, forHTTPHeaderField: "Payload-HMAC")
  }
  
  func getBody() -> NSString {
    return NSString(data: urlRequest.httpBody!, encoding: String.Encoding.utf8.rawValue)!
  }
}
