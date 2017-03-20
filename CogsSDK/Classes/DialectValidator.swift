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

final class DialectValidator {

    static func parseAndAutoValidate(record: String, completionHandler: @escaping (JSON?, Error?, PubSubErrorResponse?) -> Void) {
        do {
            let json = try JSONSerialization.jsonObject(with: record.data(using: String.Encoding.utf8)!, options: .allowFragments) as JSON

            guard let action = json["action"] as? String else {
                let error = PubSubErrorResponse(code: Int(103), message: "Missing action from record")
                completionHandler(nil, nil, error)

                return
            }

            guard let pAction = PubSubAction(rawValue: action) else {
                let error = PubSubErrorResponse(code: Int(103), message: "Unknown action or bad record format from server")

                completionHandler(nil, nil, error)

                return
            }

            if let code = json["code"] as? Int {
                guard let pCode = PubSubResponseCode(rawValue: code) else {
                    let error = PubSubErrorResponse(code: Int(103), message: "Unknown response code")

                    completionHandler(nil, nil, error)

                    return
                }

                if pCode.rawValue != 200 {
                    let error = try! PubSubErrorResponse(json: json)
                    completionHandler(nil, nil, error)
                } else {
                    completionHandler(json, nil, nil)
                }
            } else {
                if pAction != .message {
                    let error = PubSubErrorResponse(code: Int(103), message: "Missing code from record")
                    completionHandler(nil, nil, error)

                    return
                } else {
                    completionHandler(json, nil, nil)
                }
            }
        } catch {
            let error = NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot construct JSON from record"])
            completionHandler(nil, error, nil)
        }
    }
}
