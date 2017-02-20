
import Foundation
import CryptoSwift

class SocketAuthentication {

    /// Compute the auth hmac for the specified keys.
    ///
    /// - Parameter keys: passed keys
    /// - Returns: payloadBase64 and payloadHmac strings
    static func authenticate(keys: [String]) -> (payloadBase64: String, payloadHmac: String) {

        if keys.isEmpty {
            assertionFailure("No keys supplied")
        }

        var dict: [String: AuthKey] = [:]
        for key in keys {
            let authKey = AuthKey(keyAsString: key)
            dict[authKey.perm] = authKey
        }
        
        var permissions: String = ""
        for key in dict.values {
            permissions += key.perm
        }

        let identity: String  = dict.first!.value.identity
        let timestamp: String = Date().toISO8601

        let params: [String: Any] = [
            "identity": identity,
            "permissions": permissions,
            "security_timestamp": timestamp
        ]

        let payloadData: Data = try! JSONSerialization.data(withJSONObject: params, options: .init(rawValue: 0))
        let payload = String(NSString(data: payloadData, encoding: String.Encoding.utf8.rawValue)!)

        var hmacXored: [UInt8] = [UInt8](repeating: 0, count: 32)
         let bodyBuffer = [UInt8](payload.utf8)

        for key in dict.values {
            let buffer = key.permKey.hexToByteArray()
            let hmac: [UInt8] = try! HMAC(key: buffer, variant: .sha256).authenticate(bodyBuffer)
            let hmacHexString = hmac.toHexString()

            mutateXor(target: &hmacXored, source: hmac)
        }

        let data: Data = payload.data(using: String.Encoding.utf8)!
        let payloadBase64: String = data.base64EncodedString(options: .endLineWithLineFeed)
        let payloadHmac: String = hmacXored.toHexString()

        return (payloadBase64: payloadBase64, payloadHmac: payloadHmac)
    }

    /// Mutate the target array by xoring it with the source array. The arrays must be the same length.
    ///
    /// - Parameters:
    ///   - target: array to be changed
    ///   - source: array the target will be xored with
    private static func mutateXor(target: inout [UInt8], source: [UInt8]) {
        guard target.count == source.count else {
            assertionFailure("Target and source array must be with equal lengths")

            return
        }

        for i in 0..<target.count {
            target[i] = target[i] ^ source[i]
        }
    }
}
