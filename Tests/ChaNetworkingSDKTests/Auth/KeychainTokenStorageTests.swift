//
//  KeychainTokenStorageTests.swift
//  ChaNetworkingSDK
//
//  Created by 차순혁 on 2026/07/22.
//

import Foundation
import Testing
@testable import ChaNetworkingSDK

@Suite(.serialized)
struct KeychainTokenStorageTests {
    @Test func saveTokenPairPersistsBothTokens() throws {
        let storage = makeStorage()
        defer { try? storage.clearTokens() }

        try storage.saveTokenPair(
            TokenPair(
                accessToken: "access_token",
                refreshToken: "refresh_token"
            )
        )

        let tokenPair = storage.getTokenPair()
        #expect(tokenPair?.accessToken == "access_token")
        #expect(tokenPair?.refreshToken == "refresh_token")
    }

    @Test func saveTokenPairReplacesBothTokens() throws {
        let storage = makeStorage()
        defer { try? storage.clearTokens() }

        try storage.saveTokenPair(
            TokenPair(
                accessToken: "old_access_token",
                refreshToken: "old_refresh_token"
            )
        )

        try storage.saveTokenPair(
            TokenPair(
                accessToken: "new_access_token",
                refreshToken: "new_refresh_token"
            )
        )

        let tokenPair = storage.getTokenPair()
        #expect(tokenPair?.accessToken == "new_access_token")
        #expect(tokenPair?.refreshToken == "new_refresh_token")
    }

    @Test func clearTokensRemovesBothTokens() throws {
        let storage = makeStorage()
        defer { try? storage.clearTokens() }

        try storage.saveTokenPair(
            TokenPair(
                accessToken: "access_token",
                refreshToken: "refresh_token"
            )
        )
        try storage.clearTokens()

        #expect(storage.getTokenPair() == nil)
    }

    private func makeStorage() -> KeychainTokenStorage {
        KeychainTokenStorage(
            service: "com.chanetworking.sdk.tests.\(UUID().uuidString)"
        )
    }
}
