// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import RxSwift

extension HTTP {
    /// Creates an observable for HTTP Delete operation and parses result using the specified Decodable
    ///
    /// - Parameters:
    ///   - service:    The service for the API call. Used as baseURL
    ///   - path:       The relative path for the API call. Appended to the baseURL.
    ///   - parameters: A dictionary with params to be sent as query params
    ///   - headers:    A [String: String] dictionary mapping HTTP header field names to values. Defaults to nil.
    ///   - timeout:    How many seconds before the request times out. Defaults to 15.0
    ///   - respType:   Decodable model used to parse json to given model
    ///
    /// - Returns: An instance of Single<T>.
    public static func delete<T>(
        service: HTTPService,
        path: String,
        parameters: [String: String]? = nil,
        headers: [String: String]? = nil,
        timeout: TimeInterval = HTTP.kDefaultTimeout,
        for responseType: T.Type
    ) -> Single<HTTPResponse<T>> where T: Decodable {
        let request = HTTPRequest<T>(
            service: service,
            method: .delete,
            path: path,
            parameters: parameters,
            headers: headers,
            timeout: timeout,
            for: responseType
        )

        return HTTP.makeDecodableRequest(request: request)
    }

    /// Creates an observable for HTTP Delete operation and parses result using the specified closure
    ///
    /// - Parameters:
    ///   - service:    The service for the API call. Used as baseURL
    ///   - path:       The relative path for the API call. Appended to the baseURL.
    ///   - parameters: A dictionary with params to be sent as query params
    ///   - headers:    A [String: String] dictionary mapping HTTP header field names to values. Defaults to nil.
    ///   - timeout:    How many seconds before the request times out. Defaults to 15.0
    ///   - parser:     Closure called to parse Data to given model
    ///
    /// - Returns: An instance of Single<T>.
    public static func delete(
        service: HTTPService,
        path: String,
        parameters: [String: String]? = nil,
        headers: [String: String]? = nil,
        timeout: TimeInterval = HTTP.kDefaultTimeout
    ) -> Single<Data> {
        let request = HTTPRequest<Data>(
            service: service,
            method: .delete,
            path: path,
            parameters: parameters,
            headers: headers,
            timeout: timeout
        )

        return HTTP.makeDataRequest(request: request)
    }
}
