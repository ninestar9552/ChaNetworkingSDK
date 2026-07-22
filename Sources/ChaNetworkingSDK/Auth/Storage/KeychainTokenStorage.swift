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
    private let tokenPairKey = "token_pair"

    /// Keychain 저장소 초기화
    /// - Parameter service: Keychain service identifier
    ///   (기본값: "com.chanetworking.sdk.auth")
    public init(service: String = "com.chanetworking.sdk.auth") {
        self.service = service
    }

    public func saveTokenPair(_ tokenPair: TokenPair) throws {
        try save(tokenPair)
    }

    public func getTokenPair() -> TokenPair? {
        guard let data = getData(forKey: tokenPairKey) else {
            return nil
        }

        return try? JSONDecoder().decode(TokenPair.self, from: data)
    }

    public func clearTokens() throws {
        try delete(forKey: tokenPairKey)
    }

    // MARK: - Private Helpers

    private func save(_ tokenPair: TokenPair) throws {
        guard let data = try? JSONEncoder().encode(tokenPair) else {
            throw KeychainError.encodingError
        }

        let query = baseQuery(forKey: tokenPairKey)
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw KeychainError.saveFailed(updateStatus)
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError.saveFailed(addStatus)
        }
    }

    private func getData(forKey key: String) -> Data? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return data
    }

    private func delete(forKey key: String) throws {
        let status = SecItemDelete(baseQuery(forKey: key) as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    private func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
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
