//
//  BasicAuthAdapter.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/14/25.
//

import Foundation
import Alamofire

/// Basic Authentication을 처리하는 Adapter
/// Username과 Password를 Base64 인코딩하여 Authorization 헤더에 추가
public final class BasicAuthAdapter: RequestInterceptor {
    private let username: String
    private let password: String

    /// Basic Auth Adapter 초기화
    /// - Parameters:
    ///   - username: 사용자 이름
    ///   - password: 비밀번호
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    // MARK: - RequestAdapter

    public func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var urlRequest = urlRequest

        // Authorization 헤더에 추가
        urlRequest.headers.add(.authorization(username: username, password: password))

        completion(.success(urlRequest))
    }
}
