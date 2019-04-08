// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import Foundation

// Represents an HTTP method
public enum HTTPMethod: String {
    /// Post request method
    case post = "POST"

    /// Get request method
    case get = "GET"

    /// Put request method
    case put = "PUT"

    /// Delete request method
    case delete = "DELETE"
}
