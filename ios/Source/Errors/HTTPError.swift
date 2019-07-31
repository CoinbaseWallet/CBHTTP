// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import Foundation

public enum HTTPError: Error {
    /// Unknown error occurred.
    case unknown

    /// Response is not NSHTTPURLResponse
    case nonHTTPResponse(response: URLResponse)

    /// Response is not successful. (not in `200 ..< 300` range)
    case httpRequestFailed(response: HTTPURLResponse, data: Data?)

    /// Deserialization error.
    case deserializationError(error: Error)

    /// Request is not a valid URLRequest
    case invalidURLRequest

    /// Error for http request with missing payload
    case missingPayload

    /// No response parser found
    case missingResponseParser

    public var statusCode: Int? {
        switch self {
        case let .httpRequestFailed(response, _):
            return response.statusCode
        default:
            return nil
        }
    }
}
