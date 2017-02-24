
import Foundation


/// PubSub service options
open class PubSubOptions {

    open let url: String
    open let connectionTimeout: Int
    open let autoReconnect: Bool

    public init(url: String, timeout: Int, autoReconnect: Bool) {
        self.url               = url
        self.connectionTimeout = timeout
        self.autoReconnect     = autoReconnect
    }

//    public static let defaultOptions: PubSubOptions = PubSubOptions(url: "", timeout: 30, autoReconnect: true)
}
