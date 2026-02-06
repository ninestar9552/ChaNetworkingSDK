//
//  BearerTokenClient.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/14/25.
//

import Foundation
import Alamofire

/// Bearer Token 인증을 사용하는 Network Client
/// - 자동으로 모든 요청에 Bearer Token 추가
/// - 401 에러 발생 시 자동으로 Token 갱신 후 1번 재시도
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
open class BearerTokenClient: NetworkClient, EndpointClient {
    public let baseURL: String
    public let tokenStorage: TokenStorage

    /// BearerTokenClient 초기화
    /// - Parameters:
    ///   - baseURL: API Base URL (예: "https://api.example.com")
    ///   - configuration: URLSession configuration (기본값: .default)
    ///   - tokenStorage: Token 저장소 (기본값: KeychainTokenStorage)
    ///   - tokenRefresher: Token 갱신 로직을 구현한 클로저
    ///   - encoding: 파라미터 인코딩 전략 (기본값: JSONEncoding)
    ///   - errorHandler: 에러 핸들러 (기본값: DefaultNetworkErrorHandler)
    ///   - logging: 로깅 활성화 여부 (기본값: false)
    public init(
        baseURL: String,
        configuration: URLSessionConfiguration = .default,
        tokenStorage: TokenStorage = KeychainTokenStorage(),
        tokenRefresher: @escaping TokenRefreshHandler,
        encoding: ParameterEncoding = JSONEncoding.default,
        errorHandler: NetworkErrorHandler = DefaultNetworkErrorHandler(),
        logging: Bool = false
    ) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.tokenStorage = tokenStorage

        // BearerTokenAdapter와 BearerTokenRetrier 생성
        let adapter = BearerTokenAdapter(tokenStorage: tokenStorage)
        let retrier = BearerTokenRetrier(
            tokenStorage: tokenStorage,
            tokenRefresher: tokenRefresher
        )

        // Interceptor로 결합
        let interceptor = Interceptor(adapter: adapter, retrier: retrier)

        // Session with Interceptor 생성
        let session = Session(
            configuration: configuration,
            interceptor: interceptor
        )

        super.init(
            session: session,
            encoding: encoding,
            errorHandler: errorHandler,
            logging: logging
        )
    }
}
