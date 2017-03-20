//
//  DialectValidator.swift
//  CogsSDK
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

struct AuthKey {
    
    private static let validKeyParts: String = "RWA"

    let perm     : String
    let identity : String
    let permKey  : String

    /// Parse and validate project key
    ///
    /// - Parameter keyAsString: passed string to parse
    init(keyAsString: String) {
        let keyParts: [String] = keyAsString.components(separatedBy: "-")

        if keyParts.count != 3 {
            assertionFailure("Invalid format for project key.")
        }

        if !AuthKey.validKeyParts.contains(keyParts[0]) {
            assertionFailure("Invalid permission prefix for project key. The valid prefixes are \(AuthKey.validKeyParts)")
        }

        if !keyParts[1].matches(regex: "[0-9a-fA-F]") {
            assertionFailure("Invalid format for identity key.")
        }

        if !keyParts[2].matches(regex: "[0-9a-fA-F]") {
            assertionFailure("Invalid format for perm key.")
        }

        perm     = keyParts[0]
        identity = keyParts[1]
        permKey  = keyParts[2]
    }
}
