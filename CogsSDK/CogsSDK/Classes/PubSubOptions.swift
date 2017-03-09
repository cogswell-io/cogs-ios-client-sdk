
import Foundation


/// PubSub service options
open class PubSubOptions {

    open let url: String
    open let connectionTimeout: Int
    open let autoReconnect: Bool
    open let minReconnectDelay: TimeInterval
    open let maxReconnectDelay: TimeInterval
    open let maxReconnectAttempts: Int


    /// PubSubOptions configuration
    ///
    /// - Parameters:
    ///   - url: URL to which to connect
    ///   - connectionTimeout: Time before connection should timeout
    ///   - autoReconnect: true if connection should attempt to reconnect when disconnected
    ///   - minReconnectDelay: The initial amount of time a reconnection attempt waits before attempting to reconnect.
    ///   - maxReconnectDelay: The maximum amount of time a reconnection attempt should wait before attempting to reconnect
    ///   - maxReconnectAttempts: The number of times to attempt a reconnection.  -1 signifies infinite tries
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

    public static let defaultOptions: PubSubOptions = PubSubOptions(url: "",
                                                                    connectionTimeout: 30,
                                                                    autoReconnect: true,
                                                                    minReconnectDelay: 5,
                                                                    maxReconnectDelay: 300,
                                                                    maxReconnectAttempts: -1)
}
