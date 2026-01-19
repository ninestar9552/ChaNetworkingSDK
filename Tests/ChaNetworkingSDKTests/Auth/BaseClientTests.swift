//
//  BaseClientTests.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Testing
import XCTest
import Foundation
import Alamofire
@testable import ChaNetworkingSDK

// MARK: - BaseClient Tests
final class BaseClientTests {

    // Helper: 테스트용 클라이언트 생성
    func createTestClient() -> (client: BaseClient, key: String) {
        let key = UUID().uuidString

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.httpAdditionalHeaders = ["X-Test-ID": key]

        let client = BaseClient(
            baseURL: "https://api.example.com",
            configuration: configuration,
            logging: true
        )
        return (client, key)
    }

    // MARK: - Basic Request Test
    @Test func testBasicRequest() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        let mockJSON = #"{"id":1,"name":"Test User"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            // URL 경로 검증
            #expect(request.url?.absoluteString == "https://api.example.com/users/me")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: API 호출
        let response: ApiResponse<MockUser> = try await client.get("/users/me")

        // Then: 정상 응답 검증
        #expect(response.value.id == 1)
        #expect(response.value.name == "Test User")
        #expect(response.httpResponse.statusCode == 200)
    }

    // MARK: - No Authorization Header Test
    @Test func testNoAuthorizationHeader() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        var capturedAuthHeader: String?
        let mockJSON = #"{"id":1,"name":"Test User"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            // Authorization 헤더 캡처
            capturedAuthHeader = request.value(forHTTPHeaderField: "Authorization")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: API 호출
        let _: ApiResponse<MockUser> = try await client.get("/users/me")

        // Then: Authorization 헤더가 없어야 함
        #expect(capturedAuthHeader == nil)
    }

    // MARK: - Convenience Methods Test
    @Test func testConvenienceMethods() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // GET
        let getResponse: ApiResponse<MockUser> = try await client.get("/users/1")
        #expect(getResponse.httpResponse.statusCode == 200)

        // POST
        let postResponse: ApiResponse<MockUser> = try await client.post(
            "/users",
            parameters: ["name": "New User"]
        )
        #expect(postResponse.httpResponse.statusCode == 200)

        // PUT
        let putResponse: ApiResponse<MockUser> = try await client.put(
            "/users/1",
            parameters: ["name": "Updated"]
        )
        #expect(putResponse.httpResponse.statusCode == 200)

        // PATCH
        let patchResponse: ApiResponse<MockUser> = try await client.patch(
            "/users/1",
            parameters: ["name": "Patched"]
        )
        #expect(patchResponse.httpResponse.statusCode == 200)
    }

    // MARK: - Empty Response Test
    @Test func testEmptyResponse() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())  // 빈 응답
        }

        // When: DELETE with EmptyResponse
        let response: ApiResponse<ChaNetworkingSDK.EmptyResponse> = try await client.delete("/users/1")

        // Then
        #expect(response.httpResponse.statusCode == 204)
        #expect(response.data.isEmpty)
    }

    // MARK: - Server Error Test
    @Test func testServerError() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        let mockJSON = #"{"error":"Not Found"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        do {
            let _: ApiResponse<MockUser> = try await client.get("/users/999")
            #expect(false, "Expected error was not thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code, let message):
                #expect(code == 404)
                #expect(message == #"{"error":"Not Found"}"#)
            default:
                #expect(false, "Unexpected error type: \(error)")
            }
        }
    }

    // MARK: - URL Building Test
    @Test func testURLBuilding() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        var capturedURLs: [String] = []
        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            capturedURLs.append(request.url?.absoluteString ?? "")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // 상대 경로 (슬래시 있음)
        let _: ApiResponse<MockUser> = try await client.get("/users/1")
        #expect(capturedURLs.last == "https://api.example.com/users/1")

        // 상대 경로 (슬래시 없음)
        let _: ApiResponse<MockUser> = try await client.get("posts/1")
        #expect(capturedURLs.last == "https://api.example.com/posts/1")

        // 전체 URL (그대로 사용)
        let _: ApiResponse<MockUser> = try await client.get("https://other-api.com/data")
        #expect(capturedURLs.last == "https://other-api.com/data")
    }

    // MARK: - Encodable Query Test
    @Test func testEncodableQuery() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        struct SearchQuery: Encodable {
            let keyword: String
            let page: Int
            let limit: Int
        }

        var capturedURL: String?
        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            capturedURL = request.url?.absoluteString
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: Encodable 쿼리로 GET 요청
        let query = SearchQuery(keyword: "test", page: 1, limit: 20)
        let _: ApiResponse<MockUser> = try await client.get("/search", query: query)

        // Then: URL에 쿼리 파라미터가 포함되어야 함
        #expect(capturedURL?.contains("keyword=test") == true)
        #expect(capturedURL?.contains("page=1") == true)
        #expect(capturedURL?.contains("limit=20") == true)
    }

    // MARK: - Encodable Body Test
    @Test func testEncodableBody() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        struct CreateUserRequest: Encodable {
            let name: String
            let email: String
        }

        var capturedBody: [String: Any]?
        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            // Body 캡처
            if let bodyData = request.httpBodyStream {
                let data = Data(reading: bodyData)
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: Encodable body로 POST 요청
        let body = CreateUserRequest(name: "Cha", email: "cha@example.com")
        let _: ApiResponse<MockUser> = try await client.post("/users", body: body)

        // Then: Body에 JSON이 포함되어야 함
        #expect(capturedBody?["name"] as? String == "Cha")
        #expect(capturedBody?["email"] as? String == "cha@example.com")
    }
}

// MARK: - InputStream Helper
private extension Data {
    init(reading input: InputStream) {
        self.init()
        input.open()
        defer { input.close() }

        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            if read < 0 {
                break
            } else if read == 0 {
                break
            }
            self.append(buffer, count: read)
        }
    }
}
