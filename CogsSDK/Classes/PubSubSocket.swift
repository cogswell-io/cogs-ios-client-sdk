
import Foundation
import Starscream

final class PubSubSocket: Socket {

    private var webSocket: WebSocket
    private var autoReconnect: Bool = false
    private var sequence: Int = 0
    var isConnected: Bool {
        return webSocket.isConnected
    }

    private var keys: [String]!
    var options: PubSubOptions
    var onConnect: ((Void) -> Void)?
    var onDisconnect: ((NSError?) -> Void)?
    var onText: ((String) -> Void)?
    var onError: ((Error) -> ())?

    init(keys: [String], options: PubSubOptions?) {

        if let ops = options {
            self.options           = ops
        } else {
            self.options           = PubSubOptions.defaultOptions
        }

        self.keys                  = keys

        webSocket                  = WebSocket(url: URL(string: self.options.url)!)
        webSocket.timeout          = self.options.connectionTimeout

        webSocket.onConnect = { [weak self] in
            guard let weakSelf = self else { return }

            weakSelf.onConnect?()
        }

        webSocket.onDisconnect = { [weak self] (error: NSError?) in
            guard let weakSelf = self else { return }

            weakSelf.onDisconnect?(error)
        }

        webSocket.onText = { [weak self] (text: String) in
            guard let weakSelf = self else { return }

            weakSelf.onText?(text)
        }
    }

    func connect(_ sessionUUID: String?) {
        let headers = SocketAuthentication.authenticate(keys: keys, sessionUUID: sessionUUID)

        webSocket.headers["Payload"] = headers.payloadBase64
        webSocket.headers["PayloadHMAC"] = headers.payloadHmac

        webSocket.connect()
    }

     func disconnect() {
        webSocket.disconnect()
    }

    func getSessionUUID(_ params: [String: Any]) {
        writeToSocket(params)
    }

    func subscribe(_ params: [String: Any]) {
        writeToSocket(params)
    }

    func unsubscribe(_ params: [String : Any]) {
        writeToSocket(params)
    }

    func unsubscribeAll(_ params: [String : Any]) {
        writeToSocket(params)
    }

    func listSubscriptions(_ params: [String : Any]) {
        writeToSocket(params)
    }

    func publish(_ params: [String : Any]) {
        writeToSocket(params)
    }

    func publishWithAck(_ params: [String : Any]) {
        writeToSocket(params)
    }

    private func writeToSocket(_ params: [String: Any]) {
        guard webSocket.isConnected else {
            self.onError?(NSError(domain: WebSocket.ErrorDomain, code: Int(100), userInfo: [NSLocalizedDescriptionKey: "Web socket is disconnected"]))
            return
        }

        do {
            let data: Data = try JSONSerialization.data(withJSONObject: params, options: .init(rawValue: 0))
            webSocket.write(data: data)
        } catch {
            self.onError?(error)
        }
    }
}
