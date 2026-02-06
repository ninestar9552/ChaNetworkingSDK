//
//  NetworkClientTests.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/12/25.
//

import Testing
import Foundation
import Alamofire
import Combine
@testable import ChaNetworkingSDK

// MARK: - NetworkClient Tests
final class NetworkClientTests {
    
    func createTestClient() -> (client: NetworkClient, key: String) {
        let key = UUID().uuidString

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.httpAdditionalHeaders = ["X-Test-ID": key]

        let session = Session(configuration: configuration)
        let client = NetworkClient(session: session, logging: true)

        return (client, key)
    }

    // MARK: - Swift Concurrency Test
    @Test func testResponseDataAsync() async throws {
        let (client, key) = createTestClient()
        
        let mockJSON = #"{"id":1,"name":"Soo"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        let apiResponse: ApiResponse<MockUser> = try await client.responseData(.get, "/users")

        #expect(apiResponse.value == MockUser(id: 1, name: "Soo"))
        #expect(apiResponse.data == mockJSON)
        #expect(apiResponse.httpResponse.statusCode == 200)
    }

    // MARK: - Error Handling Test
    @Test func testServerErrorResponseAsync() async throws {
        let (client, key) = createTestClient()
        
        let mockJSON = #"{"error":"Unauthorized"}"#.data(using: .utf8)!
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
            let _: ApiResponse<MockUser> = try await client.responseData(.get, "/users")
            Issue.record("Expected error was not thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code, let message):
                #expect(code == 401)
                #expect(message == "{\"error\":\"Unauthorized\"}")
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }

    // MARK: - Combine Publisher Test
    @Test func testResponseDataPublisher() async throws {
        let (client, key) = createTestClient()
        
        let mockJSON = #"{"id":1,"name":"Soo"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        let publisher: AnyPublisher<ApiResponse<MockUser>, Error> = client.responseDataPublisher(.get, "/users")

        for try await response in publisher.values {
            #expect(response.value == MockUser(id: 1, name: "Soo"))
            #expect(response.data == mockJSON)
            #expect(response.httpResponse.statusCode == 200)
        }
    }

    // MARK: - Error Handling Publisher Test
    @Test func testServerErrorResponsePublisher() async throws {
        let (client, key) = createTestClient()
        
        let mockJSON = #"{"error":"Unauthorized"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        let publisher: AnyPublisher<ApiResponse<MockUser>, Error> = client.responseDataPublisher(.get, "/users")

        do {
            for try await _ in publisher.values {
                Issue.record("Expected error was not thrown")
            }
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code, let message):
                #expect(code == 401)
                #expect(message == "{\"error\":\"Unauthorized\"}")
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }
}
