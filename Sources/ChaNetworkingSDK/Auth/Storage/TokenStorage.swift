//
//  TokenStorage.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/14/25.
//

import Foundation

/// Access Token과 Refresh Token 쌍을 저장·조회·삭제하는 인터페이스
public protocol TokenStorage: Sendable {
    /// Access Token과 Refresh Token을 하나의 세션 값으로 저장
    func saveTokenPair(_ tokenPair: TokenPair) throws

    /// 저장된 Access Token과 Refresh Token 쌍 조회
    func getTokenPair() -> TokenPair?

    /// 모든 Token 삭제 (로그아웃 시 사용)
    func clearTokens() throws
}
