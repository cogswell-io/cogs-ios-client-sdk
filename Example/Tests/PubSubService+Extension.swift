
@testable import CogsSDK

extension PubSubService {
    public static func connect(socket: Socket) -> PubSubConnectionHandle {
        return PubSubConnectionHandle(socket: socket)
    }
}
