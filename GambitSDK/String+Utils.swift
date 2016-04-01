//
//  String+Utils.swift
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

extension String {
  func split(len: Int) -> [String] {
    var array = [String]()
    var currentIndex = 0
    let length = self.characters.count
    
    while currentIndex < length {
      let startIndex = self.startIndex.advancedBy(currentIndex)
      let endIndex = startIndex.advancedBy(len, limit: self.endIndex)
      let substr = self.substringWithRange(startIndex..<endIndex)
      array.append(substr)
      currentIndex += len
    }
    
    return array
  }
  
  func hexToByteArray() -> [UInt8] {
    return self.split(2).map() { UInt8(strtoul($0, nil, 16)) }
  }
}
