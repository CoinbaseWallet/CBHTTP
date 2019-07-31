// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import Foundation

/// The model object returned from HTTP methods
public struct HTTPResponse<T> {
    /// HTTP response headers
    public let headers: [AnyHashable: Any]

    /// Decoded HTTP response body
    public let body: T
}
