
import Foundation
import Starscream

public final class PubSubSocket: Socket {

    private var webSocket: WebSocket
    private var autoReconnect: Bool = false
    private var sequence: Int = 0
    public var isConnected: Bool {
        return webSocket.isConnected
    }

    private var keys: [String]!
    public var options: PubSubOptions

    /// On connect event handler
    public var onConnect: ((Void) -> Void)?

    /// On disconnect event handler
    public var onDisconnect: ((NSError?) -> Void)?

    /// On connect event handler
    public var onText: ((String) -> Void)?

    /// On error event handler
    public var onError: ((Error) -> ())?

    /// Description
    ///
    /// - Parameters:
    ///   - keys: The provided project keys.
    ///   - options: The connection options.
    public init(keys: [String], options: PubSubOptions?) {

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

    public func connect(_ sessionUUID: String?) {
        let headers = SocketAuthentication.authenticate(keys: keys, sessionUUID: sessionUUID)

        webSocket.headers["Payload"] = headers.payloadBase64
        webSocket.headers["PayloadHMAC"] = headers.payloadHmac

        webSocket.connect()
    }

    public func disconnect() {
        webSocket.disconnect()
    }

    public func getSessionUUID(_ params: [String: Any]) {
        writeToSocket(params)
    }

    public func subscribe(_ params: [String: Any]) {
        writeToSocket(params)
    }

    public func unsubscribe(_ params: [String : Any]) {
        writeToSocket(params)
    }

    public func unsubscribeAll(_ params: [String : Any]) {
        writeToSocket(params)
    }

    public func listSubscriptions(_ params: [String : Any]) {
        writeToSocket(params)
    }

    public func publish(_ params: [String : Any]) {
        writeToSocket(params)
    }

    public func publishWithAck(_ params: [String : Any]) {
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
