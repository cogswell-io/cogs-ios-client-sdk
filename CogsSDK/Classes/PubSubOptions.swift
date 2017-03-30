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

private let defaultURL: String                     = "wss://api.cogswell.io/pubsub"
private let defaultConnectionTimeout: Int          = 30
private let defaultAutoreconnect: Bool             = true
private let defaultMinReconnectDelay: TimeInterval = 5
private let defaultMaxReconnectDelay: TimeInterval = 300
private let defaultMaxReconnectAttempts: Int       = -1

/// Pub/Sub service options
public final class PubSubOptions {

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
    
    /// New session event handler.
    ///
    /// Indicates that the session associated with this connection is not a resumed session, therefore there are no subscriptions associated with this session. If there had been a previous session and the connection was replaced by an auto-reconnect, the previous session was not restored resulting in all subscriptions being lost.
    public var onNewSessionHandler: ((String) -> ())?

    /// Reconnect event handler.
    ///
    /// The event is emitted on socket reconnection if it disconnects for any reason.
    public var onReconnectHandler: (() -> ())?

    /// Raw record event handler.
    ///
    /// The event is emitted for every raw record received from the server, whether a response to a request or a message. This is mostly useful for debugging issues with server communication.
    public var onRawRecordHandler: ((RawRecord) -> ())?

    /// Message event handler.
    ///
    /// The event is emitted whenever the socket receives messages from any channel.
    public var onMessageHandler: ((PubSubMessage) -> ())?

    /// Close event handler
    public var onCloseHandler: ((Error?) -> ())?

    /// General error event handler.
    ///
    /// The event is emitted on any connection errors, failed publishing, or when any exception is thrown.
    public var onErrorHandler: ((Error) -> ())?

    /// Response error event handler.
    ///
    /// The event is emitted whenever a message is sent to the user with an error status code.
    public var onErrorResponseHandler: ((PubSubErrorResponse) -> ())?

    /// PubSubOptions configuration
    ///
    /// - Parameters:
    ///   - url: Cogs pub/sub service URL.
    ///   - connectionTimeout: The time before connection timeouts.
    ///   - autoReconnect: A boolean flag that shows should the connection try to reconnect when disconnected.
    ///   - minReconnectDelay: The initial amount of time the connection waits before attempting to reconnect.
    ///   - maxReconnectDelay: The maximum amount of time the connection waits before attempting to reconnect. Reconnection delay get increased with every attempt until reaching the maximum value.
    ///   - maxReconnectAttempts: The maximum number of reconnection attempts.  -1 signifies infinite tries.
    public init(url: String?,
                connectionTimeout: Int?,
                autoReconnect: Bool?,
                minReconnectDelay: TimeInterval?,
                maxReconnectDelay: TimeInterval?,
                maxReconnectAttempts: Int?,
                onNewSessionHandler: ((String) -> ())? = nil,
                onReconnectHandler: (() -> ())? = nil,
                onRawRecordHandler: ((RawRecord) -> ())? = nil,
                onMessageHandler: ((PubSubMessage) -> ())? = nil,
                onCloseHandler: ((Error?) -> ())? = nil,
                onErrorHandler: ((Error) -> ())? = nil,
                onErrorResponseHandler: ((PubSubErrorResponse) -> ())? = nil) {
        self.url                    = url ?? defaultURL
        self.connectionTimeout      = connectionTimeout ?? defaultConnectionTimeout
        self.autoReconnect          = autoReconnect ?? defaultAutoreconnect
        self.minReconnectDelay      = minReconnectDelay ?? defaultMinReconnectDelay
        self.maxReconnectDelay      = maxReconnectDelay ?? defaultMaxReconnectDelay
        self.maxReconnectAttempts   = maxReconnectAttempts ?? defaultMaxReconnectAttempts
        self.onNewSessionHandler    = onNewSessionHandler
        self.onReconnectHandler     = onReconnectHandler
        self.onRawRecordHandler     = onRawRecordHandler
        self.onMessageHandler       = onMessageHandler
        self.onCloseHandler         = onCloseHandler
        self.onErrorHandler         = onErrorHandler
        self.onErrorResponseHandler = onErrorResponseHandler
    }

    /// Default options configuration
    public static var defaultOptions: PubSubOptions {

        return PubSubOptions(url: defaultURL,
                             connectionTimeout: defaultConnectionTimeout,
                             autoReconnect: defaultAutoreconnect,
                             minReconnectDelay: defaultMinReconnectDelay,
                             maxReconnectDelay: defaultMaxReconnectDelay,
                             maxReconnectAttempts: defaultMaxReconnectAttempts)
    }
}
