//
//  TokenPair.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/14/25.
//

import Foundation

/// Access Token과 Refresh Token 쌍을 나타내는 모델
public struct TokenPair: Codable {
    public let accessToken: String
    public let refreshToken: String

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
