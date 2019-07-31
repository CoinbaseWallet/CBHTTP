// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import Foundation

/// HTTP basic authentication credentials
public struct Credentials {
    /// HTTP basic authentication username
    public let username: String

    /// HTTP basic authentication password
    public let password: String

    /// Initialize credentials with a username and password
    ///
    /// - Parameters:
    ///   - username: username for authentication
    ///   - password: password for authentication
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    /// Properly encoded and formatted HTTP basic authentication header value
    internal var basicAuth: String? {
        let credentialString = "\(username):\(password)"

        guard let data = credentialString.data(using: .utf8) else {
            return nil
        }

        return "Basic \(data.base64EncodedString())"
    }
}
