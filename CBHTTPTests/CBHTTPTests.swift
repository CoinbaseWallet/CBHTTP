// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

@testable import CBHTTP
import OHHTTPStubs
import RxBlocking
import RxSwift
import XCTest

let unitTestsTimeout: RxTimeInterval = 3

class CBHTTPTests: XCTestCase {
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testGetUserRequest() throws {
        let observable = HTTP.get(service: .identity, path: "/user/current", for: MockUser.self)
        let host = HTTPService.identity.url.host!
        let expectedUsername = "satoshi"
        let expectedID = 12345

        stub(condition: isHost(host) && isPath("/user/current")) { request in
            XCTAssertEqual(request.httpMethod, "GET")
            let json: [AnyHashable: Any] = ["id": expectedID, "username": expectedUsername]
            return OHHTTPStubsResponse(jsonObject: json, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        let user = try observable.toBlocking(timeout: unitTestsTimeout).single()
        XCTAssertEqual(expectedUsername, user.username)
        XCTAssertEqual(expectedID, user.id)
    }

    func testPostUserRequest() throws {
        let expectedUsername = "biggie"
        let expectedID = 3
        let params: [String: Any] = ["id": expectedID, "username": expectedUsername]
        let observable = HTTP.post(
            service: .identity,
            path: "/user/current",
            parameters: params,
            timeout: 20,
            for: MockPostUserResponse.self
        )

        stub(condition: isPath("/user/current")) { request in
            let params = request.jsonBodyFromInputStream

            XCTAssertNotNil(params)
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.timeoutInterval, 20)

            XCTAssertEqual(params?["id"] as? Int, expectedID)
            XCTAssertEqual(params?["username"] as? String, expectedUsername)

            let userJSON: [AnyHashable: Any] = ["id": expectedID, "username": expectedUsername]
            let json: [AnyHashable: Any] = ["status": "ok", "user": userJSON]
            return OHHTTPStubsResponse(jsonObject: json, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        let response = try observable.toBlocking(timeout: unitTestsTimeout).single()
        XCTAssertEqual("ok", response.status)
        XCTAssertEqual(expectedUsername, response.user.username)
        XCTAssertEqual(expectedID, response.user.id)
    }

    func testGetUserUsingParseClosure() throws {
        let observable = HTTP.get(service: .identity, path: "/user/current")
            .map { try JSONDecoder().decode(MockUser.self, from: $0) }

        let host = HTTPService.identity.url.host!
        let expectedUsername = "satoshi"
        let expectedID = 12345

        stub(condition: isHost(host) && isPath("/user/current")) { request in
            XCTAssertEqual(request.httpMethod, "GET")
            let json: [AnyHashable: Any] = ["id": expectedID, "username": expectedUsername]
            return OHHTTPStubsResponse(jsonObject: json, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        let user = try observable.toBlocking(timeout: unitTestsTimeout).single()
        XCTAssertEqual(expectedUsername, user.username)
        XCTAssertEqual(expectedID, user.id)
    }

    func testPutUserRequestUsingParseClosure() throws {
        let expectedUsername = "biggie"
        let expectedID = 3
        let params: [String: Any] = ["id": expectedID, "username": expectedUsername]
        let observable = HTTP.put(service: .identity, path: "/user/current", parameters: params, timeout: 20)
            .map { try JSONDecoder().decode(MockUser.self, from: $0) }

        stub(condition: isPath("/user/current")) { request in
            let params = request.jsonBodyFromInputStream

            XCTAssertNotNil(params)
            XCTAssertEqual(request.httpMethod, "PUT")
            XCTAssertEqual(request.timeoutInterval, 20)

            XCTAssertEqual(params?["id"] as? Int, expectedID)
            XCTAssertEqual(params?["username"] as? String, expectedUsername)

            let json: [AnyHashable: Any] = ["id": expectedID, "username": expectedUsername]
            return OHHTTPStubsResponse(jsonObject: json, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        let user = try observable.toBlocking(timeout: unitTestsTimeout).single()
        XCTAssertEqual(expectedUsername, user.username)
        XCTAssertEqual(expectedID, user.id)
    }

    func testDeleteUserRequestUsingDecodable() throws {
        let expectedUsername = "biggie"
        let expectedID = 3
        let host = HTTPService.identity.url.host!
        let observable = HTTP.delete(service: .identity, path: "/user", timeout: 203, for: MockUser.self)

        stub(condition: isHost(host) && isPath("/user")) { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.timeoutInterval, 203)

            let json: [AnyHashable: Any] = ["id": expectedID, "username": expectedUsername]
            return OHHTTPStubsResponse(jsonObject: json, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        let user = try observable.toBlocking(timeout: unitTestsTimeout).single()
        XCTAssertEqual(expectedUsername, user.username)
        XCTAssertEqual(expectedID, user.id)
    }

    func testOptionalGetUser() throws {
        let observable = HTTP.get(service: .identity, path: "/user/current", for: MockUser?.self)
        let host = HTTPService.identity.url.host!
        let expectedUsername = "satoshi"
        let expectedID = 12345

        stub(condition: isHost(host) && isPath("/user/current")) { request in
            XCTAssertEqual(request.httpMethod, "GET")
            let json: [AnyHashable: Any] = ["id": expectedID, "username": expectedUsername]
            return OHHTTPStubsResponse(jsonObject: json, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        let user = try observable.toBlocking(timeout: unitTestsTimeout).single()
        XCTAssertEqual(expectedUsername, user?.username)
        XCTAssertEqual(expectedID, user?.id)
    }
}

struct MockPostUserResponse: Codable {
    let status: String
    let user: MockUser
}

struct MockUser: Codable {
    let id: Int
    let username: String
}

extension URLRequest {
    var jsonBodyFromInputStream: [AnyHashable: Any]? {
        do {
            guard let data = self.httpBodyStream.map({ Data(reading: $0) }) else { return nil }
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [AnyHashable: Any]
        } catch {
            return nil
        }
    }
}

extension HTTPService {
    /// Identity service
    static let identity = HTTPService(string: "https://unittests.toshi.org")
}

extension Data {
    init(reading input: InputStream) {
        self.init()
        input.open()

        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            if read == 0 {
                break // added
            }

            append(buffer, count: read)
        }

        buffer.deallocate()

        input.close()
    }
}
