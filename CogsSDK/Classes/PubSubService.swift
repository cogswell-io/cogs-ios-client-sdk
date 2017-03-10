
import Foundation

import CryptoSwift

/// Opens a connection to the Cogswell Pub/Sub system.
public class PubSubService {

    /// Initializes and returns a service.
    public init(){}
    
    /// Creates and configures a pub/sub connection.
    ///
    /// - Parameters:
    ///   - keys: The provided project keys.
    ///   - options: The connection options.
    /// - Returns: Returns a configured pub/sub connection handler to manage the connection.
    public func connnect(keys: [String], options: PubSubOptions?) -> PubSubConnectionHandle {
        return PubSubConnectionHandle(keys: keys, options: options)
    }
}

