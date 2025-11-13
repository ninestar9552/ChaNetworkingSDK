//
//  NetworkClientTests.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/12/25.
//

import Testing
import XCTest
import Foundation
import Alamofire
import Combine
@testable import ChaNetworkingSDK

// MARK: - NetworkClient Tests
final class NetworkClientTests {

    var client: NetworkClient!
    var client2: NetworkClient!
    var cancellables = Set<AnyCancellable>()

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = Session(configuration: configuration)
        client = NetworkClient(session: session)
        
        let configuration2 = URLSessionConfiguration.ephemeral
        configuration2.protocolClasses = [MockURLProtocol2.self]
        let session2 = Session(configuration: configuration2)
        client2 = NetworkClient(session: session2)
    }

    // MARK: - Swift Concurrency Test
    @Test func testResponseDataAsync() async throws {
        let mockJSON = #"{"id":1,"name":"Soo"}"#.data(using: .utf8)!
        MockURLProtocol.HandlerStore.requestHandler = { request in
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
        let mockJSON = #"{"error":"Unauthorized"}"#.data(using: .utf8)!
        MockURLProtocol2.HandlerStore.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        do {
            let _: ApiResponse<MockUser> = try await client2.responseData(.get, "/users")
            #expect(false, "Expected error was not thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code, let message):
                #expect(code == 401)
                #expect(message == "{\"error\":\"Unauthorized\"}")
            default:
                #expect(false, "Unexpected error type: \(error)")
            }
        }
    }

    // MARK: - Combine Publisher Test
    @Test func testResponseDataPublisher() async throws {
        let mockJSON = #"{"id":1,"name":"Soo"}"#.data(using: .utf8)!
        MockURLProtocol.HandlerStore.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        let publisher: AnyPublisher<ApiResponse<MockUser>, Error> = try client.responseDataPublisher(.get, "/users")

        do {
            for try await response in publisher.values {
                #expect(response.value == MockUser(id: 1, name: "Soo"))
                #expect(response.data == mockJSON)
                #expect(response.httpResponse.statusCode == 200)
            }
        } catch {
            #expect(false, "Unexpected error type: \(error)")
        }
    }

    // MARK: - Error Handling Publisher Test
    @Test func testServerErrorResponsePublisher() async throws {
        let mockJSON = #"{"error":"Unauthorized"}"#.data(using: .utf8)!
        MockURLProtocol2.HandlerStore.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        let publisher: AnyPublisher<ApiResponse<MockUser>, Error> = try client2.responseDataPublisher(.get, "/users")

        do {
            for try await _ in publisher.values {
                #expect(false, "Expected error was not thrown")
            }
        } catch {
            if let error = error as? NetworkError {
                switch error {
                case .serverError(let code, let message):
                    #expect(code == 401)
                    #expect(message == "{\"error\":\"Unauthorized\"}")
                default:
                    #expect(false, "Unexpected error type: \(error)")
                }
            } else {
                #expect(false, "Unexpected error type: \(error)")
            }
        }
    }
}
