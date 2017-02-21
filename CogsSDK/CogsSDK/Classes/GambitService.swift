//
//  GambitService.swift
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
import CryptoSwift

private let EventEndpoint          = "event"
private let RegisterPushEndpoint   = "register_push"
private let UnregisterPushEndpoint = "unregister_push"
private let MessageEndpoint        = "message"

/// Singleton class used for all SDK services
public class GambitService {
  // MARK: Properties
  public static let sharedGambitService = GambitService()
  private let sharedSession: URLSession
  
    /// API base URL
  public var baseURL: String?

    /*
     A Private initializer prevents any other part of the app
     from creating an instance.
     */

  private init() {
    let sessionConfiguration = URLSessionConfiguration.default
    sessionConfiguration.timeoutIntervalForRequest = 30.0
    sharedSession = URLSession(configuration: sessionConfiguration)
  }
  
  /**
   Send Event data to Cogs service
   
   - parameter gambitRequest:     Configuring object see GambitRequestEvent for more info
   - parameter completionHandler: completion handler
   - returns: Void
   */
  
  public func requestEvent(_ gambitRequest: GambitRequestEvent, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
    guard let baseURL = self.baseURL else {
      print("Please enter API baseURL in GambitService.sharedGambitService")

      return
    }

    var request = Request(urlString: baseURL + EventEndpoint, method: .POST)
    
    var params = [String: AnyObject]()
    params["timestamp"]     = Date().toISO8601 as AnyObject?
    params["access_key"]    = gambitRequest.accessKey as AnyObject?
    params["client_salt"]   = gambitRequest.clientSalt as AnyObject?
    params["event_name"]    = gambitRequest.eventName as AnyObject?
    params["namespace"]     = gambitRequest.namespace as AnyObject?
    params["attributes"]    = gambitRequest.attributes as AnyObject?
    
    if let tags = gambitRequest.tags {
      params["tags"] = tags as AnyObject?
    }

    if let debugDirective = gambitRequest.debugDirective {
      params["debug_directive"] = debugDirective as AnyObject?
    }
    
    if let campaignID = gambitRequest.campaignID {
      params["campaign_id"] = campaignID as AnyObject?
    }
    
    request.setParams(params: params)
    
    let body = String(request.getBody())
    let bodyBuffer = [UInt8](body.utf8)
    let clientSecretBuffer = gambitRequest.clientSecret.hexToByteArray()

    let hmac: [UInt8] = try! HMAC(key: clientSecretBuffer, variant: .sha256).authenticate(bodyBuffer)
    
    request.setPayloadHmac(hmac.toHexString())
    
    print(NSString(data: request.urlRequest.httpBody!, encoding: String.Encoding.utf8.rawValue))
    
    let task = sharedSession.dataTask(with: request.urlRequest, completionHandler: completionHandler)

    task.resume()
  }
  
  /**
   Send Register Push request to Cogs Service. Registers for push notifications per specified CIID.
   
   - parameter gambitRequest:     Request paprameters configuring object, see GambitRequestPush for more info
   - parameter completionHandler: Completion handler
   - returns: Void
   */
  
  public func registerPush(_ gambitRequest: GambitRequestPush, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
    guard let baseURL = self.baseURL else {
      print("Please enter baseURL API in GambitService.sharedGambitService")
      return
    }

    var request = Request(urlString: baseURL + RegisterPushEndpoint, method: .POST)
    request.setParams(params: [
      "timestamp": Date().toISO8601 as AnyObject,
      "client_salt": gambitRequest.clientSalt as AnyObject,
      "udid": gambitRequest.UDID as AnyObject,
      "access_key": gambitRequest.accessKey as AnyObject,
      "attributes": gambitRequest.attributes as AnyObject,
      "environment": gambitRequest.environment as AnyObject,
      "platform_app_id": gambitRequest.applicationID as AnyObject,
      "platform": gambitRequest.platform as AnyObject,
      "namespace": gambitRequest.namespace as AnyObject
    ])
    
    let body = String(request.getBody())
    let bodyBuffer = [UInt8](body.utf8)
    let secretBuffer = gambitRequest.clientSecret.hexToByteArray()
    let hmac = try! HMAC(key: secretBuffer, variant: .sha256).authenticate(bodyBuffer)
    
    request.setPayloadHmac(hmac.toHexString())

    let task = sharedSession.dataTask(with: request.urlRequest, completionHandler: completionHandler)
    task.resume()
  }
  
  /**
   Send Register Push request to Cogs Service. Unregisters from push notifications per specified CIID.
   
   - parameter gambitRequest:     Request parameters configuring object, see GambitRequestPush for more info
   - parameter completionHandler: Completion handler
   - returns: Void
   */
  
  public func unregisterPush(_ gambitRequest: GambitRequestPush, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
    guard let baseURL = self.baseURL else {
      print("Please enter baseURL API in GambitService.sharedGambitService")
      return
    }

    var request = Request(urlString: baseURL + UnregisterPushEndpoint, method: .DELETE)
    request.setParams(params: [
      "timestamp": Date().toISO8601 as AnyObject,
      "client_salt": gambitRequest.clientSalt as AnyObject,
      "udid": gambitRequest.UDID as AnyObject,
      "access_key": gambitRequest.accessKey as AnyObject,
      "attributes": gambitRequest.attributes as AnyObject,
      "environment": gambitRequest.environment as AnyObject,
      "platform_app_id": gambitRequest.applicationID as AnyObject,
      "platform": gambitRequest.platform as AnyObject,
      "namespace": gambitRequest.namespace as AnyObject
    ])
    
    let body = String(request.getBody())
    let bodyBuffer = [UInt8](body.utf8)
    let secretBuffer = gambitRequest.clientSecret.hexToByteArray()
    let hmac = try! HMAC(key: secretBuffer, variant: .sha256).authenticate(bodyBuffer)
    
    request.setPayloadHmac(hmac.toHexString())
    
    let task = sharedSession.dataTask(with: request.urlRequest, completionHandler: completionHandler)
    task.resume()
  }
  
  /**
   Send Message request to Cogs Service. Requests message payload per message id.
   
   - parameter gambitRequest:     Request parameters configuring object, see GambitRequestMessage for more info
   - parameter completionHandler: Completion handler
   - returns: Void
   */
  
  public func message(_ gambitRequest: GambitRequestMessage, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
    guard let baseURL = self.baseURL else {
      print("Please enter baseURL API in GambitService.sharedGambitService")
      return
    }

    var request = Request(urlString: baseURL + MessageEndpoint + "/\(gambitRequest.token)", method: .GET)
    let params = [
      "access_key": gambitRequest.accessKey,
      "client_salt": gambitRequest.clientSalt,
      "namespace": gambitRequest.namespace,
      "attributes": gambitRequest.attributes,
      "timestamp": Date().toISO8601
    ] as [String : Any]
    
    var b64String: String?
    var jsonData: Data!
    
    do {
      jsonData = try JSONSerialization.data(withJSONObject: params, options: .init(rawValue: 0))
      b64String = jsonData.base64EncodedString(options: .endLineWithLineFeed)
    } catch {
      print(error)
    }
    
    guard let base64String = b64String else { return }
    
    let body = String(data: jsonData, encoding: String.Encoding.utf8)!
    let bodyBuffer = [UInt8](body.utf8)
    let clientSecretBuffer = gambitRequest.clientSecret.hexToByteArray()
    let hmac = try! HMAC(key: clientSecretBuffer, variant: .sha256).authenticate(bodyBuffer)
    
    request.setPayloadHmacAndJSON(hmac.toHexString(), json: base64String)
    
    let task = sharedSession.dataTask(with: request.urlRequest, completionHandler: completionHandler)
    task.resume()
  }
}