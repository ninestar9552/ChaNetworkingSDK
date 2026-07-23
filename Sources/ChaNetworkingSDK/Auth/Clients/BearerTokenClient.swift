//
//  BearerTokenClient.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/14/25.
//

import Foundation
import Alamofire

private struct UncheckedSendableBox<T>: @unchecked Sendable {
    let value: T
}

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
    ///   - tokenStorage: Token 저장소 (기본값: KeychainTokenStorage)
    ///   - tokenRefresher: Token 갱신 로직을 구현한 클로저
    ///   - shouldInvalidateAuthentication: refresh 오류가 인증정보를 무효화하는지 판단하는 클로저
    ///   - onAuthenticationInvalidated: 저장된 인증정보가 제거된 뒤 호출되는 이벤트
    ///   - session: Alamofire Session (기본값: 새 기본 Session)
    ///   - encoding: 파라미터 인코딩 전략 (기본값: JSONEncoding)
    ///   - errorHandler: 에러 핸들러 (기본값: DefaultNetworkErrorHandler)
    ///   - logging: 로깅 활성화 여부 (기본값: false)
    public init(
        baseURL: String,
        tokenStorage: TokenStorage = KeychainTokenStorage(),
        tokenRefresher: @escaping TokenRefreshHandler,
        shouldInvalidateAuthentication: @escaping AuthenticationInvalidationEvaluator = { _ in false },
        onAuthenticationInvalidated: @escaping AuthenticationInvalidationHandler = {},
        session: Session = Session(),
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
            tokenRefresher: tokenRefresher,
            shouldInvalidateAuthentication: shouldInvalidateAuthentication,
            onAuthenticationInvalidated: onAuthenticationInvalidated,
            logging: logging
        )

        // Interceptor로 결합
        let interceptor = Interceptor(adapter: adapter, retrier: retrier)

        super.init(
            session: session,
            requestInterceptor: interceptor,
            encoding: encoding,
            errorHandler: errorHandler,
            logging: logging
        )
    }

    /// async/await 기반 Token Refresh 클로저를 받는 편의 초기화자입니다.
    ///
    /// 기존 callback 기반 `TokenRefreshHandler`도 유지하되, Swift Concurrency 기반
    /// 서비스 앱에서는 이 초기화자를 사용하면 `Task` 래핑 코드를 앱에 둘 필요가 없습니다.
    public convenience init(
        baseURL: String,
        tokenStorage: TokenStorage = KeychainTokenStorage(),
        asyncTokenRefresher: @escaping AsyncTokenRefreshHandler,
        shouldInvalidateAuthentication: @escaping AuthenticationInvalidationEvaluator = { _ in false },
        onAuthenticationInvalidated: @escaping AuthenticationInvalidationHandler = {},
        session: Session = Session(),
        encoding: ParameterEncoding = JSONEncoding.default,
        errorHandler: NetworkErrorHandler = DefaultNetworkErrorHandler(),
        logging: Bool = false
    ) {
        self.init(
            baseURL: baseURL,
            tokenStorage: tokenStorage,
            tokenRefresher: { refreshToken, completion in
                let completionBox = UncheckedSendableBox(value: completion)
                Task {
                    do {
                        let tokens = try await asyncTokenRefresher(refreshToken)
                        completionBox.value(.success(tokens))
                    } catch {
                        completionBox.value(.failure(error))
                    }
                }
            },
            shouldInvalidateAuthentication: shouldInvalidateAuthentication,
            onAuthenticationInvalidated: onAuthenticationInvalidated,
            session: session,
            encoding: encoding,
            errorHandler: errorHandler,
            logging: logging
        )
    }
}
