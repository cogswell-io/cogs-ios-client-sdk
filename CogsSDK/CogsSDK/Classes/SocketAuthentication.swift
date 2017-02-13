
import Foundation

class SocketAuthentication {

    public static func authenticate(keys: [String]) {

        var dict: [String: AuthKey] = [:]
        let uniqueKeys: [String] = Array(Set(keys))

        for key in uniqueKeys {
            let authKey = AuthKey(keyAsString: key)
            dict[authKey.perm] = authKey
        }

        var permissions: String = ""
        for key in dict.values {
            permissions += key.perm
        }

        let identity: String  = dict.first!.value.identity
        let timestamp: String = Date().toISO8601

        let payload: String = String(format:
            "{ \"identity\": %s, \"permissions\": %s, \"security_timestamp\": %s }"
            , identity, permissions, timestamp)
    }
}
