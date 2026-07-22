//
//  MockTokenStorage.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Foundation
@testable import ChaNetworkingSDK

/// 테스트용 메모리 기반 Token 저장소 (Thread-Safe)
final class MockTokenStorage: TokenStorage, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.chanetworking.mocktokenstorage", attributes: .concurrent)
    private var _tokenPair: TokenPair?
    private var _saveTokenPairCallCount = 0

    var saveTokenPairCallCount: Int {
        queue.sync { _saveTokenPairCallCount }
    }

    func saveTokenPair(_ tokenPair: TokenPair) throws {
        queue.sync(flags: .barrier) {
            self._tokenPair = tokenPair
            self._saveTokenPairCallCount += 1
        }
    }

    func getTokenPair() -> TokenPair? {
        queue.sync { _tokenPair }
    }

    func clearTokens() throws {
        queue.sync(flags: .barrier) {
            self._tokenPair = nil
        }
    }
}
