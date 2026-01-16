//
//  BearerTokenClientTests.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Testing
import XCTest
import Foundation
import Alamofire
import Combine
@testable import ChaNetworkingSDK

// MARK: - BearerTokenClient Tests
final class BearerTokenClientTests {

    // Helper: 테스트용 클라이언트와 스토리지 생성
    func createTestClient() -> (client: BearerTokenClient, key: String, storage: MockTokenStorage) {
        let key = UUID().uuidString
        
        let tokenStorage = MockTokenStorage()

        // Token refresher mock
        let tokenRefresher: TokenRefreshHandler = { refreshToken, completion in
            // Mock: 새 토큰 발급
            completion(.success((
                accessToken: "new_access_token",
                refreshToken: "new_refresh_token"
            )))
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.httpAdditionalHeaders = ["X-Test-ID": key]

        // BearerTokenClient 생성 with mock configuration
        let client = BearerTokenClient(
            baseURL: "https://api.example.com",
            configuration: configuration,
            tokenStorage: tokenStorage,
            tokenRefresher: tokenRefresher,
            logging: true
        )

        return (client, key, tokenStorage)
    }

    // MARK: - Authorization Header Test
    @Test func testAuthorizationHeaderAdded() async throws {
        // Given: 클라이언트 생성 및 토큰 저장
        let (client, key, tokenStorage) = createTestClient()
        try tokenStorage.saveAccessToken("test_access_token")

        var capturedAuthHeader: String?
        let mockJSON = #"{"id":1,"name":"Test User"}"#.data(using: .utf8)!
        
        MockURLProtocol.setHandler(key) { request in
            // Capture: Authorization 헤더 캡처
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
        #expect(capturedAuthHeader == "Bearer test_access_token")
        #expect(response.value.id == 1)
        #expect(response.httpResponse.statusCode == 200)
    }

    // MARK: - 401 Retry Test
    @Test func testTokenRefreshOn401() async throws {
        // Given: 클라이언트 생성 및 만료된 토큰 저장
        let (client, key, tokenStorage) = createTestClient()
        try tokenStorage.saveAccessToken("expired_token")
        try tokenStorage.saveRefreshToken("valid_refresh_token")

        var requestCount = 0
        var capturedAuthHeaderOnRetry: String?
        let mockJSON = #"{"id":1,"name":"Test User"}"#.data(using: .utf8)!
        
        MockURLProtocol.setHandler(key) { request in
            requestCount += 1

            if requestCount == 1 {
                // 첫 번째 요청: 401 반환
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data())
            } else {
                // 두 번째 요청: 성공 (새 토큰으로)
                capturedAuthHeaderOnRetry = request.value(forHTTPHeaderField: "Authorization")

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, mockJSON)
            }
        }

        // When: API 호출
        let response: ApiResponse<MockUser> = try await client.get("/users/me")

        // Then: 재시도 성공 및 새 토큰으로 재시도 확인
        #expect(requestCount == 2)
        #expect(capturedAuthHeaderOnRetry == "Bearer new_access_token")
        #expect(response.httpResponse.statusCode == 200)
        #expect(tokenStorage.getAccessToken() == "new_access_token")
        #expect(tokenStorage.getRefreshToken() == "new_refresh_token")
    }

    // MARK: - Max Retry Count Test
    @Test func testMaxRetryCount() async throws {
        // Given: 클라이언트 생성 및 만료된 토큰
        let (client, key, tokenStorage) = createTestClient()
        try tokenStorage.saveAccessToken("expired_token")
        try tokenStorage.saveRefreshToken("valid_refresh_token")

        var requestCount = 0
        
        MockURLProtocol.setHandler(key) { request in
            requestCount += 1
            // 항상 401 반환
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When: API 호출
        do {
            let _: ApiResponse<MockUser> = try await client.get("/users/me")
            #expect(false, "Expected error was not thrown")
        } catch {
            // Then: 최대 2번 시도 (원래 요청 1번 + 재시도 1번)
            #expect(requestCount == 2)
        }
    }

    // MARK: - Convenience Methods Test
    @Test func testConvenienceMethods() async throws {
        // Given: 클라이언트 생성
        let (client, key, tokenStorage) = createTestClient()
        try tokenStorage.saveAccessToken("test_token")
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

        // When & Then: GET
        let getResponse: ApiResponse<MockUser> = try await client.get("/users/1")
        #expect(getResponse.httpResponse.statusCode == 200)

        // When & Then: POST
        let postResponse: ApiResponse<MockUser> = try await client.post(
            "/users",
            parameters: ["name": "New User"]
        )
        #expect(postResponse.httpResponse.statusCode == 200)

        // When & Then: PUT
        let putResponse: ApiResponse<MockUser> = try await client.put(
            "/users/1",
            parameters: ["name": "Updated"]
        )
        #expect(putResponse.httpResponse.statusCode == 200)

        // When & Then: PATCH
        let patchResponse: ApiResponse<MockUser> = try await client.patch(
            "/users/1",
            parameters: ["name": "Patched"]
        )
        #expect(patchResponse.httpResponse.statusCode == 200)
    }

    // MARK: - Empty Response Test
    @Test func testEmptyResponse() async throws {
        // Given: 클라이언트 생성
        let (client, key, tokenStorage) = createTestClient()
        try tokenStorage.saveAccessToken("test_token")
        
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
        let (client, key, tokenStorage) = createTestClient()
        try tokenStorage.saveAccessToken("test_token")

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
        let (client, key, tokenStorage) = createTestClient()
        try tokenStorage.saveAccessToken("test_token")

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
}
