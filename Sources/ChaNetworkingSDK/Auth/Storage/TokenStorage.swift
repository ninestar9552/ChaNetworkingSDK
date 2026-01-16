//
//  TokenStorage.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/14/25.
//

import Foundation

/// Token 저장소 프로토콜
/// Access Token과 Refresh Token을 저장/조회/삭제하는 인터페이스
public protocol TokenStorage: Sendable {
    /// Access Token 저장
    func saveAccessToken(_ token: String) throws

    /// Refresh Token 저장
    func saveRefreshToken(_ token: String) throws

    /// Access Token 조회
    func getAccessToken() -> String?

    /// Refresh Token 조회
    func getRefreshToken() -> String?

    /// 모든 Token 삭제 (로그아웃 시 사용)
    func clearTokens() throws
}
