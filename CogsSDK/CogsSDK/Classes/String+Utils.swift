//
//  String+Utils.swift
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

extension String {
  func split(_ len: Int) -> [String] {
    var array = [String]()
    var currentIndex = 0
    let length = self.characters.count
    
    while currentIndex < length {
      let startIndex = self.characters.index(self.startIndex, offsetBy: currentIndex)
      let endIndex = self.characters.index(startIndex, offsetBy: len, limitedBy: self.endIndex)
      let substr = self.substring(with: startIndex..<endIndex!)
      array.append(substr)
      currentIndex += len
    }
    
    return array
  }

  func hexToByteArray() -> [UInt8] {
    return self.split(2).map() { UInt8(strtoul($0, nil, 16)) }
  }

    func matches(regex: String) -> Bool {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))

            return true
        } catch let error {
            assertionFailure("Invalid regex: \(error.localizedDescription)")

            return false
        }
    }
}


