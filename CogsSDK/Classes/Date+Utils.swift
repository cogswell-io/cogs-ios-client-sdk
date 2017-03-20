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

extension Date {

    var toISO8601: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
        dateFormatter.timeZone   = TimeZone(secondsFromGMT: 0)
        dateFormatter.calendar   = Calendar(identifier: .iso8601)
        dateFormatter.locale     = Locale(identifier: "en_US_POSIX")

        return dateFormatter.string(from: self)
    }
}
