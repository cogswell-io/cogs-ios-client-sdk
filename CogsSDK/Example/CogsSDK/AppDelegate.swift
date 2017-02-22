//
//  AppDelegate.swift
//  Cogs
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

import UIKit
import CogsSDK
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


var DeviceTokenString: String = ""
var Environment: String = "production"

extension URL {
  func getKeyVals() -> Dictionary<String, String>? {
    var results = [String:String]()
    let keyValues = self.query?.components(separatedBy: "&")
    if keyValues?.count > 0 {
      for pair in keyValues! {
        let kv = pair.components(separatedBy: "=")
        if kv.count > 1 {
          results.updateValue(kv[1], forKey: kv[0])
        }
      }
      
    }
    return results
  }
}

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    sleep(3)
    
    // set API_BASE_URL
    #if DEBUG
        GambitService.sharedGambitService.baseURL = nil
    #else
        GambitService.sharedGambitService.baseURL = nil
    #endif

    // Register the supported notification types.
    let types: UIUserNotificationType = [.badge, .sound, .alert]
    let userSettings = UIUserNotificationSettings(types: types, categories: nil)
    
    application.registerUserNotificationSettings(userSettings)

    return true
  }

  func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
    if notificationSettings.types != .none {
        // Register for remote notifications
        application.registerForRemoteNotifications()
    }
  }

  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    
    if let queryString = url.getKeyVals() {
      print(queryString)
      
      let prefs = UserDefaults.standard
      prefs.setValue(queryString["access_key"], forKey: "accessKey")
      prefs.setValue(queryString["client_salt"], forKey: "clientSalt")
      prefs.setValue(queryString["client_secret"], forKey: "clientSecret")
      prefs.setValue(queryString["campaign_id"], forKey: "campaignID")
      prefs.setValue(queryString["event_name"], forKey: "eventName")
      prefs.setValue(queryString["namespace"], forKey: "namespaceName")
      prefs.setValue(queryString["application_id"], forKey: "applicationID")
      
      prefs.synchronize()
    }
    
    return true
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    application.applicationIconBadgeNumber = 0
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  
  /**
   Request Message payload per message id from Cogs service
   
   - parameter request: GambitRequestMessage
   */
  func gambitMessage(_ request: GambitRequestMessage) {
    let service = GambitService.sharedGambitService
    
    service.message(request) { data, response, error in
      do {
        guard let data = data else {
          // handle missing data response error
          DispatchQueue.main.async {
            var msg = "Request Failed"
            if let er = error {
              msg += ": \(er.localizedDescription)"
            }
            print(msg)
          }
          return
        }
        
        let json: JSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as JSON
        let msgResponse = try GambitMessageResponse(json: json)
        
        DispatchQueue.main.async {
          let alertController = UIAlertController(title: "Message Response", message: "\(msgResponse)", preferredStyle: UIAlertControllerStyle.alert)
          alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
          self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
        }

//        let parsedData = try GambitResponseEvent(json: json)
      }
      catch let error as NSError {
       DispatchQueue.main.async {
          print("Error: \(error)")
          
          if error.code == 1 {
            if let data = data {
              self.printErrorData(data)
            }
          }
        }
      }
    }
  }

  fileprivate func printErrorData(_ data: Data) {
    do {
      let json: JSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as JSON
      if let jsonString = json["message"] as? String {
        let msgJSON = try JSONSerialization.jsonObject(with: jsonString.data(using: String.Encoding.utf8)!, options: .allowFragments)
        DispatchQueue.main.async {
          let alertController = UIAlertController(title: "Message Response", message: "\(msgJSON)", preferredStyle: UIAlertControllerStyle.alert)
          alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
          self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
      }
    } catch {
      
    }
  }
  
  // MARK: Notifications
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})

    DeviceTokenString = deviceTokenString

    print(DeviceTokenString)


    #if DEBUG
      Environment = "dev"
    #else
      Environment = "production"
    #endif

    print(Environment)
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Fail to get token: \(error.localizedDescription)")
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
    
    DispatchQueue.main.async {
      let alertController = UIAlertController(title: "Push Payload", message: "\(userInfo)", preferredStyle: UIAlertControllerStyle.alert)
      var msgRequest: GambitRequestMessage?
      
      if let msgID = userInfo["aviata_gambit_message_id"] as? String {
        let prefs = UserDefaults.standard
        if let accessKey = prefs.string(forKey: "accessKey"),
          let clientSalt = prefs.string(forKey: "clientSalt"),
          let clientSecret = prefs.string(forKey: "clientSecret"),
          let namespaceName = prefs.string(forKey: "namespaceName"),
          let attributesList = prefs.string(forKey: "attributesList")
        {
          do {
            let jsonAtts = try JSONSerialization
              .jsonObject(with: attributesList.data(using: String.Encoding.utf8)!, options: .allowFragments)
            
            msgRequest = GambitRequestMessage(accessKey: accessKey, clientSalt: clientSalt, clientSecret: clientSecret, token: msgID, namespace: namespaceName, attributes: jsonAtts as! [String: AnyObject])
          }
          catch {
            print("Attributes Error! Invalid Attributes JSON.")
          }
        }
      } else {
        print("missing message ID")
      }
        
      let action = UIAlertAction(title: "View Message", style: UIAlertActionStyle.cancel) { _ in
        if msgRequest != nil {
          self.gambitMessage(msgRequest!)
        }
      }
      alertController.addAction(action)
      
      self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
  }
}

