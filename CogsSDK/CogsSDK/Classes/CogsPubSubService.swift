
import Foundation
import Starscream
import CryptoSwift

public protocol CogsPubSubServiceDelegate: class {
    func socketDidConnect()
    func socketDidDisconnect()
}

public class CogsPubSubService {

   public weak var delegate: CogsPubSubServiceDelegate?

    public static let sharedService = CogsPubSubService()
    public var baseWSURL  : String?
    private var webSocket : WebSocket?

    private init() {}

    public func connect(keys: [String]) {
        guard let url = baseWSURL else {
            assertionFailure("Please enter WSS URL in CogsPubSubService.sharedService")
            webSocket = nil

            return
        }

        webSocket = WebSocket(url: URL(string: url)!)

        guard let socket = webSocket else { return }

        socket.timeout = 30

        let headers = SocketAuthentication.authenticate(keys: keys)

        socket.headers["Payload"] = headers.payloadBase64
        socket.headers["PayloadHMAC"] = headers.payloadHmac
        socket.delegate = self

        socket.connect()
    }

    public func disconnect() {
        guard let socket = webSocket else { return }

        if socket.isConnected {
            socket.disconnect()
        }
    }

    public func getSessionUUID() {

    }

    public func subsribeToChannel() {

    }

    public func unsubsribeFromChannel() {

    }

    public func unsubsribeFromAllChannels() {

    }

    public func getAllSubscriptions() {

    }

    public func publishMessage() {

    }
}

// MARK: WebSocketDelegate
extension CogsPubSubService: WebSocketDelegate {
    public func websocketDidConnect(socket: WebSocket) {
        print("websocket is connected")
        
        delegate?.socketDidConnect()
    }

    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if let e = error {
            print("websocket is disconnected: \(e.localizedDescription)")
        } else {
            print("websocket disconnected")
        }

        delegate?.socketDidDisconnect()
    }

    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("Received text: \(text)")
    }

    public func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print("Received data: \(data.count)")
    }
}
