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
    private var _accessToken: String?
    private var _refreshToken: String?

    func saveAccessToken(_ token: String) throws {
        queue.sync(flags: .barrier) { [weak self] in
            self?._accessToken = token
        }
    }

    func saveRefreshToken(_ token: String) throws {
        queue.sync(flags: .barrier) { [weak self] in
            self?._refreshToken = token
        }
    }

    func getAccessToken() -> String? {
        return queue.sync {
            return _accessToken
        }
    }

    func getRefreshToken() -> String? {
        return queue.sync {
            return _refreshToken
        }
    }

    func clearTokens() throws {
        queue.sync(flags: .barrier) { [weak self] in
            self?._accessToken = nil
            self?._refreshToken = nil
        }
    }
}
