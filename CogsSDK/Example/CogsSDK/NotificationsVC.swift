//
//  NotificationsVC.swift
//  GambitDemo
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

class NotificationsVC: ViewController {
  
  // MARK: Outlets
  @IBOutlet weak var accessKeyField: UITextField!
  @IBOutlet weak var clientSaltField: UITextField!
  @IBOutlet weak var clientSecretField: UITextField!
  @IBOutlet weak var applicationIDField: UITextField!
  @IBOutlet weak var namespaceField: UITextField!
  @IBOutlet weak var attributesTextView: UITextView!
  @IBOutlet weak var deviceToken: UITextField!
  @IBOutlet weak var registerButton: UIButton!
  @IBOutlet weak var unregisterButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.readInputFieldsData()
    deviceToken.text = DeviceTokenString
  }
  
  /**
   Send Register Push Request to Cogs Service
   
   - parameter request: GambitRequestPush
   */
  
  fileprivate func registerPush(_ request: GambitRequestPush) {
    let service = GambitService.sharedGambitService
    let prefs = UserDefaults.standard
    let registerTopicForPush: () -> Void = {
      let dict = [
        "clientSalt" : request.clientSalt,
        "clientSecret" : request.clientSecret,
        "UDID" : request.UDID,
        "accessKey" : request.accessKey,
        "attributes" : request.attributes,
        "env" : request.environment,
        "appID" : request.applicationID,
        "namespace" : request.namespace
      ] as [String : Any]
        
      prefs.setValue(dict, forKey: "registeredPush")
      
      service.registerPush(request, completionHandler: self.completionHandler)
    }
    
    // unregister previous topic if existing
    if let registeredPush = prefs.value(forKey: "registeredPush") as? [String: AnyObject] {
      let req = GambitRequestPush(
        clientSalt: registeredPush["clientSalt"] as! String,
        clientSecret: registeredPush["clientSecret"] as! String,
        UDID: registeredPush["UDID"] as! String,
        accessKey: registeredPush["accessKey"] as! String,
        attributes: registeredPush["attributes"] as! [String: AnyObject],
        environment: registeredPush["env"] as! String,
        applicationID: registeredPush["appID"] as! String,
        namespace: registeredPush["namespace"] as! String
      )
      prefs.removeObject(forKey: "registeredPush")
      prefs.synchronize()
      
      service.unregisterPush(req) { data, response, error in
        if error == nil {
          DispatchQueue.main.async {
            registerTopicForPush()
          }
        }
      }
    } else {
      registerTopicForPush()
    }
  }
  
  /**
   Send Unregister Push Request to Cogs Service
   
   - parameter request: GambitRequestPush
   */
  
  fileprivate func unregisterPush(_ request: GambitRequestPush) {
    let service = GambitService.sharedGambitService
    
    service.unregisterPush(request, completionHandler: self.completionHandler)
  }
  
  
  fileprivate func completionHandler(_ data: Data?, response: URLResponse?, error: Error?) {

    guard let data = data else {
        DispatchQueue.main.async {
            var msg = "Request Failed"
            if let er = error {
                msg += ": \(er.localizedDescription)"
            }

            self.openAlertWithMessage(message: msg, title: "Error")
        }

        return
    }

    do {
      
      //uncomment to log raw response
//      let datastring = NSString(data: data!, encoding:NSUTF8StringEncoding)
//      print("result:",datastring)

      let json: JSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as JSON
      print(json)
      let pushResponse = try GambitResponsePush(json: json)
      
      DispatchQueue.main.async {
        self.successfulRequestResponse(pushResponse.message)
      }
    } catch {
        do {
            let json: JSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as JSON
            let responseError = try GambitErrorResponse(json: json)

            DispatchQueue.main.async {
                self.openAlertWithMessage(message: responseError.description, title: responseError.message)
            }
        } catch {
            DispatchQueue.main.async {
                self.openAlertWithMessage(message: "\(error)", title: "Error")
            }
        }
    }
    
    DispatchQueue.main.async {
      self.view.isUserInteractionEnabled = true
    }
  }
  
  fileprivate func successfulRequestResponse(_ msg: String) {
    openAlertWithMessage(message: msg, title: "API Response")
  }
  
  fileprivate func openAlertWithMessage(message msg: String, title: String) {
    let actionCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
    let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
    actionCtrl.addAction(action)
    
    self.present(actionCtrl, animated: true, completion: nil)
  }
  
  @IBAction func sendRequest(_ sender: UIButton) {
    guard let accessKey = accessKeyField.text, !accessKey.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let clientSalt = clientSaltField.text, !clientSalt.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let clientSecret = clientSecretField.text, !clientSecret.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let applicationID = applicationIDField.text, !applicationID.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let namespace = namespaceField.text, !namespace.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let token = deviceToken.text, !token.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    
    self.writeInputFieldsData()
    
    do {
      let jsonAtts = try JSONSerialization
        .jsonObject(with: attributesTextView.text.data(using: String.Encoding.utf8)!, options: .allowFragments)
      guard let attributes = jsonAtts as? [String: AnyObject] else { return }

      let request = GambitRequestPush(
        clientSalt: clientSalt,
        clientSecret: clientSecret,
        UDID: token,
        accessKey: accessKey,
        attributes: attributes,
        environment: Environment,
        applicationID: applicationID,
        namespace: namespace
      )
      
      view.isUserInteractionEnabled = false
      if sender.isEqual(self.registerButton) {
        self.registerPush(request)
      } else {
        self.unregisterPush(request)
      }
    }
    catch {
      openAlertWithMessage(message: "Invalid Attributes JSON", title: "Error")
    }
  }
  
  // MARK: Utilities
  fileprivate func writeInputFieldsData(){
    let prefs = UserDefaults.standard
    prefs.setValue(self.accessKeyField.text, forKey: "accessKey")
    prefs.setValue(self.clientSaltField.text, forKey: "clientSalt")
    prefs.setValue(self.clientSecretField.text, forKey: "clientSecret")
    prefs.setValue(self.namespaceField.text, forKey: "namespaceName")
    prefs.setValue(self.attributesTextView.text, forKey: "attributesList")
    prefs.setValue(self.applicationIDField.text, forKey: "applicationID")
    
    prefs.synchronize()
  }
  
  fileprivate func readInputFieldsData(){
    let prefs = UserDefaults.standard
    if let accessKey = prefs.string(forKey: "accessKey") {
      self.accessKeyField.text = accessKey
    }
    if let clientSalt = prefs.string(forKey: "clientSalt") {
      self.clientSaltField.text = clientSalt
    }
    if let clientSecret = prefs.string(forKey: "clientSecret") {
      self.clientSecretField.text = clientSecret
    }
    if let applicationID = prefs.string(forKey: "applicationID") {
      self.applicationIDField.text = applicationID
    }
    if let namespaceName = prefs.string(forKey: "namespaceName") {
      self.namespaceField.text = namespaceName
    }
    if let attributesList = prefs.string(forKey: "attributesList") {
      self.attributesTextView.text = attributesList
    }
  }
}
