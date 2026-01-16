//
//  KeychainTokenStorage.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/14/25.
//

import Foundation
import Security

/// Keychain을 사용한 안전한 Token 저장소
public final class KeychainTokenStorage: TokenStorage {
    private let service: String
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"

    /// Keychain 저장소 초기화
    /// - Parameter service: Keychain service identifier
    ///   (기본값: "com.chanetworking.sdk.auth")
    public init(service: String = "com.chanetworking.sdk.auth") {
        self.service = service
    }

    public func saveAccessToken(_ token: String) throws {
        try save(token, forKey: accessTokenKey)
    }

    public func saveRefreshToken(_ token: String) throws {
        try save(token, forKey: refreshTokenKey)
    }

    public func getAccessToken() -> String? {
        return get(forKey: accessTokenKey)
    }

    public func getRefreshToken() -> String? {
        return get(forKey: refreshTokenKey)
    }

    public func clearTokens() throws {
        try delete(forKey: accessTokenKey)
        try delete(forKey: refreshTokenKey)
    }

    // MARK: - Private Helpers

    private func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingError
        }

        // 기존 값 삭제
        try? delete(forKey: key)

        // 새 값 저장
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Keychain Error

public enum KeychainError: Error, LocalizedError {
    case encodingError
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .encodingError:
            return "Failed to encode token data"
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        }
    }
}
