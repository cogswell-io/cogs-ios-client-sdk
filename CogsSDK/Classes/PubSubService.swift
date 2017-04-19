//
//  PubSubService.swift
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

/// Opens a connection to Cogswell pub/pub system.
public final class PubSubService {

    /// Creates and configures a pub/sub connection.
    ///
    /// - Parameters:
    ///   - keys: The provided project keys.
    ///   - options: The connection options.
    /// - Returns: Returns a configured pub/sub connection handler to manage the connection.
    public static func connect(keys: [String], options: PubSubOptions?) -> PubSubConnectionHandle {
        let socket = PubSubSocket(keys: keys, options: options)
        
        return PubSubConnectionHandle(socket: socket)
    }
}
