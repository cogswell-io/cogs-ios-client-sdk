//
//  GambitService.swift
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

private let EventEndpoint = "event"
private let RegisterPushEndpoint = "register_push"
private let UnregisterPushEndpoint = "unregister_push"
private let MessageEndpoint = "message"

/// Singleton class used for all SDK services
public class GambitService {
  // MARK: Properties
  public static let sharedGambitService = GambitService()
  private let sharedSession: NSURLSession
  
    /// API base URL
  public var baseURL : String?
  
  private init() {
    /*
      A Private initializer prevents any other part of the app
      from creating an instance.
    */
    
    let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    sessionConfiguration.timeoutIntervalForRequest = 30.0
    sharedSession = NSURLSession(configuration: sessionConfiguration)
  }
  
  /**
   Send Event data to Cogs service
   
   - parameter gambitRequest:     Configuring object see GambitRequestEvent for more info
   - parameter completionHandler: completion handler
   - returns: Void
   */
  
  public func requestEvent(gambitRequest: GambitRequestEvent, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
    guard let baseURL = self.baseURL else {
      print("Please enter baseURL API in GambitService.sharedGambitService")
      return
    }
    let request = Request(urlString: baseURL + EventEndpoint, method: .POST)
    
    var params = [String: AnyObject]()
    params["timestamp"]   = getTimestamps()
    params["access_key"]  = gambitRequest.accessKey
    params["client_salt"] = gambitRequest.clientSalt
    params["client_salt"] = gambitRequest.clientSalt
    params["event_name"]  = gambitRequest.eventName
    params["namespace"]   = gambitRequest.namespace
    params["attributes"]  = gambitRequest.attributes
    
    if let tags = gambitRequest.tags {
      params["tags"] = tags
    }
    if let debugDirective = gambitRequest.debugDirective {
      params["debug_directive"] = debugDirective
    }
    if let campaignID = gambitRequest.campaignID {
      params["campaign_id"] = campaignID
    }
    
    request.setParams(params)
    
    let body = String(request.getBody())
    let bodyBuffer = [UInt8](body.utf8)
    let clientSecretBuffer = gambitRequest.clientSecret.hexToByteArray()
    let hmac = try! Authenticator.HMAC(key: clientSecretBuffer, variant: .sha256).authenticate(bodyBuffer)
    
    request.setPayloadHmac(hmac.toHexString())
    
//    print(NSString(data: request.urlRequest.HTTPBody!, encoding: NSUTF8StringEncoding))
    
    let task = sharedSession.dataTaskWithRequest(request.urlRequest, completionHandler: completionHandler)
    task.resume()
  }
  
  /**
   Send Register Push request to Cogs Service. Registers for push notifications per specified CIID.
   
   - parameter gambitRequest:     Request paprameters configuring object, see GambitRequestPush for more info
   - parameter completionHandler: Completion handler
   - returns: Void
   */
  
  public func registerPush(gambitRequest: GambitRequestPush, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
    guard let baseURL = self.baseURL else {
      print("Please enter baseURL API in GambitService.sharedGambitService")
      return
    }
    let request = Request(urlString: baseURL + RegisterPushEndpoint, method: .POST)
    request.setParams([
      "timestamp": getTimestamps(),
      "client_salt": gambitRequest.clientSalt,
      "udid": gambitRequest.UDID,
      "access_key": gambitRequest.accessKey,
      "attributes": gambitRequest.attributes,
      "environment": gambitRequest.environment,
      "platform_app_id": gambitRequest.platformAppID,
      "platform": gambitRequest.platform,
      "namespace": gambitRequest.namespace
    ])
    
    let body = String(request.getBody())
    let bodyBuffer = [UInt8](body.utf8)
    let secretBuffer = gambitRequest.clientSecret.hexToByteArray()
    let hmac = try! Authenticator.HMAC(key: secretBuffer, variant: .sha256).authenticate(bodyBuffer)
    
    request.setPayloadHmac(hmac.toHexString())
    
    let task = sharedSession.dataTaskWithRequest(request.urlRequest, completionHandler: completionHandler)
    task.resume()
  }
  
  /**
   Send Register Push request to Cogs Service. Unregisters from push notifications per specified CIID.
   
   - parameter gambitRequest:     Request parameters configuring object, see GambitRequestPush for more info
   - parameter completionHandler: Completion handler
   - returns: Void
   */
  
  public func unregisterPush(gambitRequest: GambitRequestPush, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
    guard let baseURL = self.baseURL else {
      print("Please enter baseURL API in GambitService.sharedGambitService")
      return
    }
    let request = Request(urlString: baseURL + UnregisterPushEndpoint, method: .DELETE)
    request.setParams([
      "timestamp": getTimestamps(),
      "client_salt": gambitRequest.clientSalt,
      "udid": gambitRequest.UDID,
      "access_key": gambitRequest.accessKey,
      "attributes": gambitRequest.attributes,
      "environment": gambitRequest.environment,
      "platform_app_id": gambitRequest.platformAppID,
      "platform": gambitRequest.platform,
      "namespace": gambitRequest.namespace
    ])
    
    let body = String(request.getBody())
    let bodyBuffer = [UInt8](body.utf8)
    let secretBuffer = gambitRequest.clientSecret.hexToByteArray()
    let hmac = try! Authenticator.HMAC(key: secretBuffer, variant: .sha256).authenticate(bodyBuffer)
    
    request.setPayloadHmac(hmac.toHexString())
    
    let task = sharedSession.dataTaskWithRequest(request.urlRequest, completionHandler: completionHandler)
    task.resume()
  }
  
  /**
   Send Message request to Cogs Service. Requests message payload per message id.
   
   - parameter gambitRequest:     Request parameters configuring object, see GambitRequestMessage for more info
   - parameter completionHandler: Completion handler
   - returns: Void
   */
  
  public func message(gambitRequest: GambitRequestMessage, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
    guard let baseURL = self.baseURL else {
      print("Please enter baseURL API in GambitService.sharedGambitService")
      return
    }
    let request = Request(urlString: baseURL + MessageEndpoint + "/\(gambitRequest.token)", method: .GET)
    let params = [
      "access_key": gambitRequest.accessKey,
      "client_salt": gambitRequest.clientSalt,
      "namespace": gambitRequest.namespace,
      "attributes": gambitRequest.attributes,
      "timestamp": getTimestamps()
    ]
    
    var b64String: String?
    var jsonData: NSData!
    
    do {
      jsonData = try NSJSONSerialization.dataWithJSONObject(params, options: .init(rawValue: 0))
      b64String = jsonData.base64EncodedStringWithOptions(.EncodingEndLineWithLineFeed)
    } catch {
      print(error)
    }
    
    guard let base64String = b64String else { return }
    
    let body = String(data: jsonData, encoding: NSUTF8StringEncoding)!
    let bodyBuffer = [UInt8](body.utf8)
    let clientSecretBuffer = gambitRequest.clientSecret.hexToByteArray()
    let hmac = try! Authenticator.HMAC(key: clientSecretBuffer, variant: .sha256).authenticate(bodyBuffer)
    
    request.setPayloadHmacAndJSON(hmac.toHexString(), json: base64String)
    
    let task = sharedSession.dataTaskWithRequest(request.urlRequest, completionHandler: completionHandler)
    task.resume()
  }
  
  // MARK: Utilities
  private func getTimestamps() -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
    dateFormatter.timeZone   = NSTimeZone(forSecondsFromGMT: 0)
    dateFormatter.calendar   = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)!
    dateFormatter.locale     = NSLocale(localeIdentifier: "en_US_POSIX")
    
    return dateFormatter.stringFromDate(NSDate())
  }
}







