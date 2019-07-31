// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import Foundation

/// Represents base URL for services
public struct HTTPService {
    /// Base url for service
    public let url: URL

    /// Constructor for URL
    public init(url: URL) {
        self.url = url
    }

    /// Constructor for string based URL
    public init(string: String) {
        guard let url = URL(string: string) else {
            fatalError("Unable to parse URL for \(string) service")
        }

        self.init(url: url)
    }
}
