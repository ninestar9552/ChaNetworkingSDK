//
//  EmptyResponseTests.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Testing
import Foundation
import Alamofire
@testable import ChaNetworkingSDK

// MARK: - EmptyResponse Tests
final class EmptyResponseTests {

    // Helper: 테스트용 클라이언트 생성
    func createTestClient() -> (client: NetworkClient, key: String) {
        let key = UUID().uuidString

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.httpAdditionalHeaders = ["X-Test-ID": key]

        let session = Session(configuration: configuration)
        let client = NetworkClient(session: session, logging: true)

        return (client, key)
    }

    @Test func testEmptyResponseWith204() async throws {
        // Given: 클라이언트 생성 및 204 No Content 응답
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

        // When
        let response: ApiResponse<ChaNetworkingSDK.EmptyResponse> = try await client.responseData(
            .delete,
            "https://api.example.com/users/1"
        )

        // Then
        #expect(response.httpResponse.statusCode == 204)
        #expect(response.data.isEmpty)
    }

    @Test func testEmptyResponseWith200() async throws {
        // Given: 클라이언트 생성 및 200 OK but empty body
        let (client, key) = createTestClient()
        
        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "{}".data(using: .utf8)!)
        }

        // When
        let response: ApiResponse<ChaNetworkingSDK.EmptyResponse> = try await client.responseData(
            .post,
            "https://api.example.com/users/1/activate"
        )

        // Then
        #expect(response.httpResponse.statusCode == 200)
        #expect(!response.data.isEmpty)
    }

    @Test func testEmptyResponseDecoding() throws {
        // Given: 빈 JSON 객체
        let emptyJSON = "{}".data(using: .utf8)!
        let decoder = JSONDecoder()

        // When
        let decoded = try decoder.decode(ChaNetworkingSDK.EmptyResponse.self, from: emptyJSON)

        // Then: 디코딩 성공
        #expect(decoded != nil)
    }

    @Test func testEmptyResponseEquality() {
        // Given
        let response1 = ChaNetworkingSDK.EmptyResponse()
        let response2 = ChaNetworkingSDK.EmptyResponse()

        // Then: 모든 EmptyResponse 인스턴스는 동일
        #expect(response1 == response2)
    }

    @Test func testEmptyResponseEncoding() throws {
        // Given
        let emptyResponse = ChaNetworkingSDK.EmptyResponse()
        let encoder = JSONEncoder()

        // When
        let encoded = try encoder.encode(emptyResponse)
        let jsonString = String(data: encoded, encoding: .utf8)

        // Then: 빈 JSON 객체로 인코딩됨
        #expect(jsonString == "{}")
    }
}
