//
//  EventVC.swift
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

class EventVC: ViewController {
  @IBOutlet weak var accessKeyTextField: UITextField!
  @IBOutlet weak var clientSaltTextField: UITextField!
  @IBOutlet weak var clientSecretTextField: UITextField!
  @IBOutlet weak var campaignIDTextField: UITextField!
  @IBOutlet weak var eventNameTextField: UITextField!
  @IBOutlet weak var namespaceTextField: UITextField!
  @IBOutlet weak var attributesTextView: UITextView!
  @IBOutlet weak var label: UILabel!
    
  var directive: String?
    
  @IBAction func executeTapped(_ sender: UIBarButtonItem) {
    
    self.writeInputFieldsData()
    
    do {
      let jsonAtts = try JSONSerialization
        .jsonObject(with: attributesTextView.text.data(using: String.Encoding.utf8)!, options: .allowFragments)
      
      self.makeRequest(jsonAtts as AnyObject)
    }
    catch {
      openAlertWithMessage(message: "Invalid Attributes JSON.", title: "Attributes Error!")
    }
  }
  
  @IBAction func debugDirectiveSwitched(_ sender: UISwitch) {
    if sender.isOn {
      self.directive = "echo-as-message"
    } else {
      self.directive = nil
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.readInputFieldsData()
  }
  
  /**
   Send Event to Cogs Service
   
   - parameter atts: JSON attributes
   */
  
  fileprivate func makeRequest(_ atts: AnyObject) {
    
    guard let accessKey = accessKeyTextField.text, !accessKey.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }

    guard let clientSalt = clientSaltTextField.text, !clientSalt.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }

    guard let clientSecret = clientSecretTextField.text, !clientSecret.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }

    guard let eventName = eventNameTextField.text, !eventName.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }

    guard let namespace = namespaceTextField.text, !namespace.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }

    guard let attributes = atts as? [String: AnyObject], !attributes.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    
    let request = GambitRequestEvent(
      debugDirective: directive,
      accessKey: accessKey,
      clientSalt: clientSalt,
      clientSecret: clientSecret,
      campaignID: Int(campaignIDTextField.text ?? ""),
      eventName: eventName,
      namespace: namespace,
      attributes: attributes)
    
    let service = GambitService.sharedGambitService
    
    view.isUserInteractionEnabled = false
    service.requestEvent(request) { (data, response, error) -> Void in

        guard let data = data else {
            // handle missing data response error
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
        let json: JSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as JSON
        print("JSON: \(json)")
        let parsedData = try GambitResponseEvent(json: json)
        
        DispatchQueue.main.async {
          self.label.text = "Message: \(parsedData.message)"
          self.view.isUserInteractionEnabled = true
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
                self.view.isUserInteractionEnabled = true
            }
        }
        // handle catched errors
        DispatchQueue.main.async {
          self.openAlertWithMessage(message: "\(error)", title: "Error")
          self.view.isUserInteractionEnabled = true
        }
      }
    }
  }
  
  // MARK: Utilities
  fileprivate func openAlertWithMessage(message msg: String, title: String) {
    let actionCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
    let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
    actionCtrl.addAction(action)
    
    self.present(actionCtrl, animated: true, completion: nil)
  }
  
  fileprivate func writeInputFieldsData(){
    let prefs = UserDefaults.standard
    prefs.setValue(self.accessKeyTextField.text, forKey: "accessKey")
    prefs.setValue(self.clientSaltTextField.text, forKey: "clientSalt")
    prefs.setValue(self.clientSecretTextField.text, forKey: "clientSecret")
    prefs.setValue(self.campaignIDTextField.text, forKey: "campaignID")
    prefs.setValue(self.eventNameTextField.text, forKey: "eventName")
    prefs.setValue(self.namespaceTextField.text, forKey: "namespaceName")
    prefs.setValue(self.attributesTextView.text, forKey: "attributesList")
    
    prefs.synchronize()
  }
  
  fileprivate func readInputFieldsData(){
    let prefs = UserDefaults.standard
    if let accessKey = prefs.string(forKey: "accessKey") {
      self.accessKeyTextField.text = accessKey
    }
    if let clientSalt = prefs.string(forKey: "clientSalt") {
        self.clientSaltTextField.text = clientSalt
    }
    if let clientSecret = prefs.string(forKey: "clientSecret") {
        self.clientSecretTextField.text = clientSecret
    }
    if let campaignID = prefs.string(forKey: "campaignID") {
      self.campaignIDTextField.text = campaignID
    }
    if let eventName = prefs.string(forKey: "eventName") {
      self.eventNameTextField.text = eventName
    }
    if let namespaceName = prefs.string(forKey: "namespaceName") {
      self.namespaceTextField.text = namespaceName
    }
    if let attributesList = prefs.string(forKey: "attributesList") {
        self.attributesTextView.text = attributesList
    }
  }
}
