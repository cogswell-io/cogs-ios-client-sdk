
import Foundation

public protocol Socket {

    var isConnected: Bool { get }
    var options: PubSubOptions { get set }
    
    var onConnect: ((Void) -> Void)? { get set }
    var onDisconnect: ((NSError?) -> Void)? { get set }
    var onText: ((String) -> Void)? { get set }
    var onError: ((Error) -> ())? { get set }

    func connect(_ sessionUUID: String?)
    func disconnect()
    func getSessionUUID(_ params: [String: Any])
    func subscribe(_ params: [String: Any])
    func unsubscribe(_ params: [String: Any])
    func unsubscribeAll(_ params: [String: Any])
    func listSubscriptions(_ params: [String: Any])
    func publish(_ params: [String: Any])
    func publishWithAck(_ params: [String: Any])
}
