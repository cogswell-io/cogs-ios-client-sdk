
import Foundation
import Starscream
import CryptoSwift

public class CogsPubSubService {

    public static let sharedPubSubService = CogsPubSubService()
    public var baseWSURL  : String?
    private var webSocket : WebSocket?

    private init() {
        guard let url = baseWSURL else {
            print("Please enter WSS URL in CogsPubSubService.sharedPubSubService")
            webSocket = nil

            return
        }

        webSocket = WebSocket(url: URL(string: url)!)
        webSocket!.timeout = 30
    }

    public func connect(read: String, write: String) {
        guard let socket = webSocket else { return }

        let r = "6481112d4758dc51c59360ca7124742b8ee36ea80f02ff9762f9b4dc62e79e5c8c5e23c11acd9beccad99fee10bfb690"
        let data = (r).data(using: String.Encoding.utf8)
        let base64 = data!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))

        let w = "W6481112d4758dc51c59360ca7124742be15d6a5a1bd755b5a37abcb6f10230e44bf08a05196881b70adf28112f80dc83"


        socket.headers["Payload"] = base64
        socket.headers["PayloadHMAC"] = ""

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
