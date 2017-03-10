
import Foundation

struct AuthKey {
    
    private static let validKeyParts: String = "RWA"

    let perm     : String
    let identity : String
    let permKey  : String

    /// Parse and validate project key
    ///
    /// - Parameter keyAsString: passed string to parse
    init(keyAsString: String) {
        let keyParts: [String] = keyAsString.components(separatedBy: "-")

        if keyParts.count != 3 {
            assertionFailure("Invalid format for project key.")
        }

        if !AuthKey.validKeyParts.contains(keyParts[0]) {
            assertionFailure("Invalid permission prefix for project key. The valid prefixes are \(AuthKey.validKeyParts)")
        }

        if !keyParts[1].matches(regex: "[0-9a-fA-F]") {
            assertionFailure("Invalid format for identity key.")
        }

        if !keyParts[2].matches(regex: "[0-9a-fA-F]") {
            assertionFailure("Invalid format for perm key.")
        }

        perm     = keyParts[0]
        identity = keyParts[1]
        permKey  = keyParts[2]
    }
}
