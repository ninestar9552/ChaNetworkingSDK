//
//  BearerTokenAdapter.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/14/25.
//

import Foundation
import Alamofire

/// Bearer Token을 요청 헤더에 자동으로 추가하는 Adapter
/// - 모든 요청에 `Authorization: Bearer {token}` 헤더를 추가합니다
public final class BearerTokenAdapter: RequestAdapter {
    let tokenStorage: TokenStorage  // internal: 테스트 접근 가능

    /// BearerTokenAdapter 초기화
    /// - Parameter tokenStorage: Token 저장소 (기본값: KeychainTokenStorage)
    public init(tokenStorage: TokenStorage = KeychainTokenStorage()) {
        self.tokenStorage = tokenStorage
    }

    // MARK: - RequestAdapter

    public func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var urlRequest = urlRequest

        // Access Token이 있으면 Authorization 헤더에 추가
        if let accessToken = tokenStorage.getAccessToken() {
            urlRequest.headers.add(.authorization(bearerToken: accessToken))
        }

        completion(.success(urlRequest))
    }
}
