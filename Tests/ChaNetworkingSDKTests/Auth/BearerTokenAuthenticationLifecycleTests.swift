//
//  BearerTokenAuthenticationLifecycleTests.swift
//  ChaNetworkingSDK
//
//  Created by 차순혁 on 2026/07/23.
//

import Alamofire
import Foundation
import Testing
@testable import ChaNetworkingSDK

final class BearerTokenAuthenticationLifecycleTests {
    private func makeSession(identifier: String) -> Session {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.httpAdditionalHeaders = ["X-Test-ID": identifier]
        return Session(configuration: configuration)
    }

    private func storeExpiredTokenPair(
        in tokenStorage: MockTokenStorage,
        refreshToken: String = "valid_refresh_token"
    ) throws {
        try tokenStorage.saveTokenPair(
            TokenPair(
                accessToken: "expired_token",
                refreshToken: refreshToken
            )
        )
    }

    private func respondUnauthorized(identifier: String) {
        MockURLProtocol.setHandler(identifier) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
    }

    @Test func concurrent401RequestsShareSingleRefresh() async throws {
        let identifier = UUID().uuidString
        let tokenStorage = MockTokenStorage()
        try storeExpiredTokenPair(in: tokenStorage)
        let refreshCount = LockedCounter()
        let client = BearerTokenClient(
            baseURL: "https://api.example.com",
            tokenStorage: tokenStorage,
            asyncTokenRefresher: { _ in
                refreshCount.increment()
                try await Task.sleep(nanoseconds: 20_000_000)
                return TokenPair(
                    accessToken: "new_access_token",
                    refreshToken: "new_refresh_token"
                )
            },
            session: makeSession(identifier: identifier)
        )
        let clientBox = UncheckedSendableValue(value: client)
        let mockJSON = #"{"id":1,"name":"Test User"}"#.data(using: .utf8)!

        MockURLProtocol.setHandler(identifier) { request in
            let isExpiredToken = request.value(
                forHTTPHeaderField: "Authorization"
            ) == "Bearer expired_token"
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: isExpiredToken ? 401 : 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, isExpiredToken ? Data() : mockJSON)
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    let _: ApiResponse<MockUser> = try await clientBox.value.get(
                        "/users/me"
                    )
                }
            }
            try await group.waitForAll()
        }

        #expect(refreshCount.value == 1)
        #expect(tokenStorage.getTokenPair()?.accessToken == "new_access_token")
        #expect(tokenStorage.getTokenPair()?.refreshToken == "new_refresh_token")
    }

    @Test func second401InvalidatesAuthenticationAfterSingleRetry() async throws {
        let identifier = UUID().uuidString
        let tokenStorage = MockTokenStorage()
        try storeExpiredTokenPair(in: tokenStorage)
        let invalidationCount = LockedCounter()
        let requestCount = LockedCounter()
        let client = BearerTokenClient(
            baseURL: "https://api.example.com",
            tokenStorage: tokenStorage,
            asyncTokenRefresher: { _ in
                TokenPair(
                    accessToken: "new_access_token",
                    refreshToken: "new_refresh_token"
                )
            },
            onAuthenticationInvalidated: {
                invalidationCount.increment()
            },
            session: makeSession(identifier: identifier),
            logging: true
        )

        MockURLProtocol.setHandler(identifier) { request in
            requestCount.increment()
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            let _: ApiResponse<MockUser> = try await client.get("/users/me")
            Issue.record("Expected error was not thrown")
        } catch {
            #expect(requestCount.value == 2)
            #expect(invalidationCount.value == 1)
            #expect(tokenStorage.getTokenPair() == nil)
        }
    }

    @Test func temporaryRefreshFailurePreservesAuthentication() async throws {
        let identifier = UUID().uuidString
        let tokenStorage = MockTokenStorage()
        try storeExpiredTokenPair(in: tokenStorage)
        let invalidationCount = LockedCounter()
        let client = BearerTokenClient(
            baseURL: "https://api.example.com",
            tokenStorage: tokenStorage,
            asyncTokenRefresher: { _ in
                throw TokenRefreshTestError.temporarilyUnavailable
            },
            shouldInvalidateAuthentication: { _ in false },
            onAuthenticationInvalidated: {
                invalidationCount.increment()
            },
            session: makeSession(identifier: identifier)
        )
        respondUnauthorized(identifier: identifier)

        do {
            let _: ApiResponse<MockUser> = try await client.get("/users/me")
            Issue.record("Expected error was not thrown")
        } catch let error as TokenRefreshTestError {
            #expect(error == .temporarilyUnavailable)
            #expect(invalidationCount.value == 0)
            #expect(tokenStorage.getTokenPair()?.accessToken == "expired_token")
            #expect(tokenStorage.getTokenPair()?.refreshToken == "valid_refresh_token")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test func rejectedRefreshInvalidatesAuthentication() async throws {
        let identifier = UUID().uuidString
        let tokenStorage = MockTokenStorage()
        try storeExpiredTokenPair(
            in: tokenStorage,
            refreshToken: "invalid_refresh_token"
        )
        let invalidationCount = LockedCounter()
        let client = BearerTokenClient(
            baseURL: "https://api.example.com",
            tokenStorage: tokenStorage,
            asyncTokenRefresher: { _ in
                throw TokenRefreshTestError.authenticationRejected
            },
            shouldInvalidateAuthentication: { error in
                error as? TokenRefreshTestError == .authenticationRejected
            },
            onAuthenticationInvalidated: {
                invalidationCount.increment()
            },
            session: makeSession(identifier: identifier)
        )
        respondUnauthorized(identifier: identifier)

        do {
            let _: ApiResponse<MockUser> = try await client.get("/users/me")
            Issue.record("Expected error was not thrown")
        } catch let error as TokenRefreshTestError {
            #expect(error == .authenticationRejected)
            #expect(invalidationCount.value == 1)
            #expect(tokenStorage.getTokenPair() == nil)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test func missingRefreshTokenInvalidatesWithoutCallingRefresher() async throws {
        let identifier = UUID().uuidString
        let tokenStorage = MockTokenStorage()
        try storeExpiredTokenPair(in: tokenStorage, refreshToken: "")
        let refreshCount = LockedCounter()
        let invalidationCount = LockedCounter()
        let client = BearerTokenClient(
            baseURL: "https://api.example.com",
            tokenStorage: tokenStorage,
            asyncTokenRefresher: { _ in
                refreshCount.increment()
                return TokenPair(accessToken: "unused", refreshToken: "unused")
            },
            onAuthenticationInvalidated: {
                invalidationCount.increment()
            },
            session: makeSession(identifier: identifier)
        )
        respondUnauthorized(identifier: identifier)

        do {
            let _: ApiResponse<MockUser> = try await client.get("/users/me")
            Issue.record("Expected error was not thrown")
        } catch {
            #expect(refreshCount.value == 0)
            #expect(invalidationCount.value == 1)
            #expect(tokenStorage.getTokenPair() == nil)
        }
    }

    @Test func refreshedTokenStorageFailureInvalidatesAuthentication() async throws {
        let identifier = UUID().uuidString
        let tokenStorage = FailingSaveTokenStorage(
            tokenPair: TokenPair(
                accessToken: "expired_token",
                refreshToken: "valid_refresh_token"
            )
        )
        let invalidationCount = LockedCounter()
        let client = BearerTokenClient(
            baseURL: "https://api.example.com",
            tokenStorage: tokenStorage,
            asyncTokenRefresher: { _ in
                TokenPair(
                    accessToken: "new_access_token",
                    refreshToken: "new_refresh_token"
                )
            },
            onAuthenticationInvalidated: {
                invalidationCount.increment()
            },
            session: makeSession(identifier: identifier)
        )
        respondUnauthorized(identifier: identifier)

        do {
            let _: ApiResponse<MockUser> = try await client.get("/users/me")
            Issue.record("Expected error was not thrown")
        } catch {
            #expect(invalidationCount.value == 1)
            #expect(tokenStorage.getTokenPair() == nil)
        }
    }
}

private final class LockedCounter: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.chanetworking.tests.lockedcounter")
    private var count = 0

    var value: Int {
        queue.sync { count }
    }

    func increment() {
        queue.sync {
            count += 1
        }
    }
}

private struct UncheckedSendableValue<Value>: @unchecked Sendable {
    let value: Value
}

private final class FailingSaveTokenStorage: TokenStorage, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.chanetworking.tests.failingstorage")
    private var tokenPair: TokenPair?

    init(tokenPair: TokenPair) {
        self.tokenPair = tokenPair
    }

    func saveTokenPair(_ tokenPair: TokenPair) throws {
        throw TokenRefreshTestError.storageFailed
    }

    func getTokenPair() -> TokenPair? {
        queue.sync { tokenPair }
    }

    func clearTokens() throws {
        queue.sync {
            tokenPair = nil
        }
    }
}

private enum TokenRefreshTestError: Error, Equatable {
    case temporarilyUnavailable
    case authenticationRejected
    case storageFailed
}
