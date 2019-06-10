// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import Foundation

/// HTTP basic authentication credentials
public struct Credentials {
    /// HTTP basic authentication username
    public let username: String

    /// HTTP basic authentication password
    public let password: String

    internal var basicAuth: String? {
        let credentialString = "\(username):\(password)"

        guard let data = credentialString.data(using: .utf8) else {
            return nil
        }

        return "Basic \(data.base64EncodedString())"
    }
}
