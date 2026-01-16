//
//  BasicAuthClientTests.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Testing
import XCTest
import Foundation
import Alamofire
@testable import ChaNetworkingSDK

// MARK: - BasicAuthClient Tests
final class BasicAuthClientTests {

    // Helper: 테스트용 클라이언트 생성
    func createTestClient() -> (client: BasicAuthClient, key: String) {
        let key = UUID().uuidString
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.httpAdditionalHeaders = ["X-Test-ID": key]

        let client = BasicAuthClient(
            baseURL: "https://api.example.com",
            configuration: configuration,
            username: "test_user",
            password: "test_password",
            logging: true)
        return (client, key)
    }

    // MARK: - Basic Auth Header Test
    @Test func testBasicAuthHeaderAdded() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        var capturedAuthHeader: String?
        let mockJSON = #"{"id":1,"name":"Test User"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            // Capture: Basic Auth 헤더 캡처
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
        let response: ApiResponse<MockUser> = try await client.get("/users/me")

        // Then: 정상 응답 및 헤더 검증
        // "test_user:test_password"를 Base64 인코딩
        let credentials = "test_user:test_password"
        let base64Credentials = credentials.data(using: .utf8)!.base64EncodedString()
        let expectedHeader = "Basic \(base64Credentials)"

        #expect(capturedAuthHeader == expectedHeader)
        #expect(response.value.id == 1)
        #expect(response.httpResponse.statusCode == 200)
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

    // MARK: - 401 Error Test
    @Test func testUnauthorizedError() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()
        
        let mockJSON = #"{"error":"Invalid credentials"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        do {
            let _: ApiResponse<MockUser> = try await client.get("/users/me")
            #expect(false, "Expected error was not thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code, let message):
                #expect(code == 401)
                #expect(message == #"{"error":"Invalid credentials"}"#)
            default:
                #expect(false, "Unexpected error type: \(error)")
            }
        }
    }
}
