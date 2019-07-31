// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import RxSwift

extension HTTP {
    /// Creates an observable for HTTP Put operation and parses result using the specified Decodable
    ///
    /// - Parameters:
    ///   - service:     The service for the API call. Used as baseURL
    ///   - path:        The relative path for the API call. Appended to the baseURL.
    ///   - credentials: HTTP basic auth credentials
    ///   - parameters:  A JSON object, to be sent as the HTTP body data.
    ///   - headers:     A [String: String] dictionary mapping HTTP header field names to values. Defaults to nil.
    ///   - timeout:     How many seconds before the request times out. Defaults to 15.0
    ///   - respType:    Decodable model used to parse json to given model
    ///
    /// - Returns: An instance of Single<T>.
    public static func put<T>(
        service: HTTPService,
        path: String,
        credentials: Credentials? = nil,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        timeout: TimeInterval = HTTP.kDefaultTimeout,
        for responseType: T.Type
    ) -> Single<HTTPResponse<T>> where T: Decodable {
        let request = HTTPRequest<T>(
            service: service,
            method: .put,
            credentials: credentials,
            path: path,
            parameters: parameters,
            headers: headers,
            timeout: timeout,
            for: responseType
        )

        return HTTP.makeDecodableRequest(request: request)
    }

    /// Creates an observable for HTTP Put operation and parses result using the specified closure
    ///
    /// - Parameters:
    ///   - service:     The service for the API call. Used as baseURL
    ///   - path:        The relative path for the API call. Appended to the baseURL.
    ///   - credentials: HTTP basic auth credentials
    ///   - parameters:  A JSON object, to be sent as the HTTP body data.
    ///   - headers:     A [String: String] dictionary mapping HTTP header field names to values. Defaults to nil.
    ///   - timeout:     How many seconds before the request times out. Defaults to 15.0
    ///   - parser:      Closure called to parse Data to given model
    ///
    /// - Returns: An instance of Single<T>.
    public static func put(
        service: HTTPService,
        path: String,
        credentials: Credentials? = nil,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        timeout: TimeInterval = HTTP.kDefaultTimeout
    ) -> Single<Data> {
        let request = HTTPRequest<Data?>(
            service: service,
            method: .put,
            credentials: credentials,
            path: path,
            parameters: parameters,
            headers: headers,
            timeout: timeout
        )

        return HTTP.makeDataRequest(request: request)
    }
}
