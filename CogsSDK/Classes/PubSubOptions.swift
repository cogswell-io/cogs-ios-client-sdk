//
//  PubSubOptions.swift
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

/// Pub/Sub service options
open class PubSubOptions {

    /// Cogs pub/sub service URL.
    open let url: String
    /// The time before connection timeouts.
    open let connectionTimeout: Int
    /// A boolean flag that shows should the connection try to reconnect when disconnected.
    open let autoReconnect: Bool
    /// Initial amount of time the connection waits before attempting to reconnect.
    open let minReconnectDelay: TimeInterval
    /// Maximum amount of time the connection waits before attempting to reconnect. Reconnection delay get increased with every attempt until reaching the maximum value.
    open let maxReconnectDelay: TimeInterval
    /// Maximum number of reconnection attempts.  -1 signifies infinite tries.
    open let maxReconnectAttempts: Int


    /// PubSubOptions configuration
    ///
    /// - Parameters:
    ///   - url: Cogs pub/sub service URL.
    ///   - connectionTimeout: The time before connection timeouts.
    ///   - autoReconnect: A boolean flag that shows should the connection try to reconnect when disconnected.
    ///   - minReconnectDelay: The initial amount of time the connection waits before attempting to reconnect.
    ///   - maxReconnectDelay: The maximum amount of time the connection waits before attempting to reconnect. Reconnection delay get increased with every attempt until reaching the maximum value.
    ///   - maxReconnectAttempts: The maximum number of reconnection attempts.  -1 signifies infinite tries.
    public init(url: String, connectionTimeout: Int,
                autoReconnect: Bool, minReconnectDelay: TimeInterval,
                maxReconnectDelay: TimeInterval, maxReconnectAttempts: Int) {
        self.url                  = url
        self.connectionTimeout    = connectionTimeout
        self.autoReconnect        = autoReconnect
        self.minReconnectDelay    = minReconnectDelay
        self.maxReconnectDelay    = maxReconnectDelay
        self.maxReconnectAttempts = maxReconnectAttempts
    }

    public static var defaultOptions: PubSubOptions {

        return PubSubOptions(url: "",
                             connectionTimeout: 30,
                             autoReconnect: true,
                             minReconnectDelay: 5,
                             maxReconnectDelay: 300,
                             maxReconnectAttempts: -1)
    }
}
