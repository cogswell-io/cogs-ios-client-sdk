
import Foundation

import CryptoSwift

/// Opens a connection to the Cogswell Pub/Sub system
public class CogsPubSubService {

    public init(){}
    
    public func connnect(keys: [String], options: PubSubOptions) -> ConnectionHandle {
        
        return ConnectionHandle(keys: keys, options: options)
    }
}

