// Copyright (c) 2017-2018 Coinbase Inc. See LICENSE

import Foundation

/// Closure for parsing response from Data to given model
public typealias HTTPResponseParser<T> = (Data?) throws -> T

/// Represents all details needed to make an HTTP request
public struct HTTPRequest<T> {
    /// Service base URL
    public let baseURL: URL

    /// HTTP method i.e. GET, POST, PUT, etc
    public let method: HTTPMethod

    /// Service relevant path
    public let path: String

    /// Optional headers
    public let headers: [String: String]?

    /// Optional parameters
    public let parameters: [String: Any]?

    /// Optional body data
    public let data: Data?

    /// Request timeout. Default set to 15 seconds
    public let timeout: TimeInterval

    /// Response parser. Used to convert response from Data to given model
    public let responseParser: HTTPResponseParser<T>?

    /// Default constuctor
    ///
    /// - Parameters:
    ///   - service:    The service for the API call. Used as baseURL
    ///   - method:     HTTP method i.e. POST, GET, etc
    ///   - path:       The relative path for the API call. Appended to the baseURL.
    ///   - parameters: A JSON object, to be sent as the HTTP body data.
    ///   - data:       data bytes to be sent as the body.
    ///   - headers:    A [String: String] dictionary mapping HTTP header field names to values. Defaults to nil.
    ///   - timeout:    How many seconds before the request times out. Defaults to 15.0
    ///   - respType:   Decodable model used to parse json to given model
    public init(
        service: HTTPService,
        method: HTTPMethod,
        path: String,
        parameters: [String: Any]? = nil,
        data: Data? = nil,
        headers: [String: String]? = nil,
        timeout: TimeInterval = HTTP.kDefaultTimeout,
        parser: HTTPResponseParser<T>? = nil
    ) {
        self.path = path
        self.headers = headers
        self.parameters = parameters
        self.data = data
        self.timeout = timeout
        self.method = method
        responseParser = parser
        baseURL = service.url
    }

    /// Convert to `URLRequest`
    var asURLRequest: URLRequest? {
        var request: URLRequest?
        var component = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        component?.path = path

        switch method {
        case .get, .delete:
            component?.queryItems = parameters?
                .compactMap { key, value -> (key: String, value: String)? in
                    guard let value = value as? String else { return nil }
                    return (key: key, value: value)
                }
                .compactMap { URLQueryItem(name: $0.key, value: $0.value) }

            guard let url = component?.url else { return nil }
            request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
        case .post, .put:
            guard let url = component?.url else { return nil }
            request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)

            do {
                request?.httpBody = try JSONSerialization.data(withJSONObject: parameters ?? [:], options: [])
            } catch {
                print("[networking]: Unable to serialize request \(self)")
                return nil
            }
        }

        request?.httpMethod = method.rawValue
        request?.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers?.forEach { request?.setValue($0.value, forHTTPHeaderField: $0.key) }

        return request
    }
}

extension HTTPRequest where T: Decodable {
    /// Constructor for `Decodable` models
    ///
    /// - Parameters:
    ///   - service:    The service for the API call. Used as baseURL
    ///   - method:     HTTP method i.e. POST, GET, etc
    ///   - path:       The relative path for the API call. Appended to the baseURL.
    ///   - parameters: A JSON object, to be sent as the HTTP body data.
    ///   - headers:    A [String: String] dictionary mapping HTTP header field names to values. Defaults to nil.
    ///   - timeout:    How many seconds before the request times out. Defaults to 15.0
    ///   - parser:     Closure called to parse Data to given model
    public init(
        service: HTTPService,
        method: HTTPMethod,
        path: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        timeout: TimeInterval = HTTP.kDefaultTimeout,
        for responseType: T.Type
    ) {
        self.init(
            service: service,
            method: method,
            path: path,
            parameters: parameters,
            headers: headers,
            timeout: timeout
        ) { data in
            guard let data = data else { throw NetworkingError.missingPayload }
            return try JSONDecoder().decode(responseType, from: data) as T
        }
    }
}
