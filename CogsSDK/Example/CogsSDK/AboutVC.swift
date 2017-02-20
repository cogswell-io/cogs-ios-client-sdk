//
//  AboutVC.swift
//  CogsDemo
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

class AboutVC: UIViewController {
  
  @IBOutlet weak var textView: UITextView!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    
    if let version = Bundle.main.releaseVersionNumber,
      let build = Bundle.main.buildVersionNumber {
      
      let infoTxt = "COGs Test App\nversion \(version), build \(build)\nwww.cogswell.io\n\nby Aviata\nwww.aviatainc.com"
      textView.text = infoTxt
    }
  }
}

extension Bundle {
  
  var releaseVersionNumber: String? {
    return self.infoDictionary?["CFBundleShortVersionString"] as? String
  }
  
  var buildVersionNumber: String? {
    return self.infoDictionary?["CFBundleVersion"] as? String
  }
}
