// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import RxCocoa
import RxSwift

public struct HTTP {
    private static let executionQueue = DispatchQueue(label: "wallet.coinbase.com.HTTP", qos: .userInitiated)
    private static let configuration = URLSessionConfiguration.default

    private static var executionOperationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = HTTP.executionQueue
        return operationQueue
    }()

    private static var session: URLSession = {
        Logging.URLRequests = { _ in false }

        return URLSession(
            configuration: HTTP.configuration,
            delegate: nil,
            delegateQueue: HTTP.executionOperationQueue
        )
    }()

    /// Default timeout
    public static let kDefaultTimeout: TimeInterval = 15

    /// Makes an HTTP request based on the given request. Note: should never make public.
    ///
    /// - Parameters:
    ///     - request: An instance of `HTTPRequest` used for API call
    ///
    /// - Returns: An Single for the HTTP request
    static func makeDecodableRequest<T>(request: HTTPRequest<T>) -> Single<HTTPResponse<T>> {
        guard let responseParser = request.responseParser else {
            return .error(HTTPError.missingResponseParser)
        }

        return task(for: request).flatMap { result in
            do {
                let parsed: T = try responseParser(result.data)
                let response = HTTPResponse(headers: result.response.allHeaderFields, body: parsed)

                return .just(response)
            } catch {
                throw HTTPError.deserializationError(error: error)
            }
        }
    }

    /// Makes an HTTP request based on the given request. Note: should never make public.
    ///
    /// - Parameters:
    ///     - request: An instance of `HTTPRequest` used for API call
    ///
    /// - Returns: An Single with reponse `Data` for the HTTP request
    static func makeDataRequest<T>(request: HTTPRequest<T>) -> Single<Data> {
        return task(for: request).map { $0.data }
    }

    /// Update data using given request.
    ///
    /// - Parameters:
    ///     - data:        The data to upload
    ///     - service:     The service for the API call. Used as baseURL
    ///     - method:      HTTP method i.e. POST, GET, etc
    ///     - credentials: HTTP basic authentication credentials
    ///     - path:        The relative path for the API call. Appended to the baseURL.
    ///     - headers:     A [String: String] dictionary mapping HTTP header field names to values. Defaults to nil.
    ///     - timeout:     How many seconds before the request times out. Defaults to 15.0
    ///
    /// - Returns: An Single with reponse `Data` for the HTTP request
    public static func upload(
        data: Data,
        service: HTTPService,
        method: HTTPMethod,
        credentials: Credentials? = nil,
        path: String,
        headers: [String: String]? = nil,
        timeout: TimeInterval = 120
    ) -> Single<Data> {
        let request = HTTPRequest<Data>(
            service: service,
            method: method,
            credentials: credentials,
            path: path,
            data: data,
            headers: headers,
            timeout: timeout
        )

        return makeDataRequest(request: request)
    }

    // MARK: - Helpers

    private static func task<T>(
        for httpRequest: HTTPRequest<T>
    ) -> Single<(response: HTTPURLResponse, data: Data)> {
        let method = httpRequest.method.rawValue.uppercased()
        let path = httpRequest.path

        guard let urlRequest = httpRequest.asURLRequest else {
            print("[networking]: \(method) \(httpRequest.path) is an invalid request")
            return .error(HTTPError.invalidURLRequest)
        }

        return session.rx.response(request: urlRequest)
            .take(1)
            .asSingle()
            .map { result -> (response: HTTPURLResponse, data: Data) in
                print("[networking]: \(method) \(httpRequest.path) [\(result.response.statusCode)]")
                return result
            }
            .map { pair -> (response: HTTPURLResponse, data: Data) in
                if 200 ..< 300 ~= pair.response.statusCode { return pair }

                throw RxCocoaURLError.httpRequestFailed(response: pair.response, data: pair.data)
            }
            .catchError { error in
                guard let err = error as? RxCocoaURLError else {
                    print("[networking]: Unknown HTTP error \(error)")
                    throw error
                }

                switch err {
                case .unknown:
                    print("[networking]: \(method) \(path) [unknown error] \(err)")
                    throw HTTPError.unknown
                case let .nonHTTPResponse(response):
                    print("[networking]: \(method) \(path) [non http response \(response)] \(err)")
                    throw HTTPError.nonHTTPResponse(response: response)
                case let .httpRequestFailed(response, data):
                    print("[networking]: \(method) \(path) [\(response.statusCode)] \(err)")
                    throw HTTPError.httpRequestFailed(response: response, data: data)
                case let .deserializationError(error):
                    print("[networking]: \(method) \(path) [deserialization error] \(err)")
                    throw HTTPError.deserializationError(error: error)
                }
            }
    }
}
