//
//  BearerTokenRetrier.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/14/25.
//

import Foundation
import Alamofire

/// Token Refresh 핸들러
///
/// Refresh Token으로 새로운 Access Token과 Refresh Token을 발급받는 로직을 구현합니다.
///
/// 사용 예:
/// ```swift
/// let refresher: TokenRefreshHandler = { currentRefreshToken, completion in
///     apiClient.post("/auth/refresh", body: ["refreshToken": currentRefreshToken]) { result in
///         switch result {
///         case .success(let response):
///             completion(.success(TokenPair(
///                 accessToken: response.accessToken,
///                 refreshToken: response.refreshToken
///             )))
///         case .failure(let error):
///             completion(.failure(error))
///         }
///     }
/// }
/// ```
public typealias TokenRefreshHandler = (
    _ currentRefreshToken: String,
    _ completion: @escaping (Result<TokenPair, Error>) -> Void
) -> Void

/// Swift Concurrency 기반 Token Refresh 핸들러입니다.
public typealias AsyncTokenRefreshHandler = @Sendable (
    _ currentRefreshToken: String
) async throws -> TokenPair

/// Token 갱신 요청이 실패했을 때 저장된 인증정보를 폐기할지 판단합니다.
///
/// 네트워크 단절이나 서버의 일시적인 5xx 오류처럼 인증정보가 무효라고 확정할 수 없는
/// 실패는 `false`, refresh token 만료·무효처럼 다시 로그인해야 하는 실패는 `true`를
/// 반환합니다.
public typealias AuthenticationInvalidationEvaluator = @Sendable (
    _ refreshError: any Error
) -> Bool

/// 저장된 인증정보를 더 이상 사용할 수 없을 때 서비스 앱에 전달하는 이벤트입니다.
///
/// SDK는 저장된 token pair를 먼저 제거하고 이 handler를 호출합니다. 화면 전환이나 앱의
/// 로그인 상태 변경은 서비스 앱의 session 계층에서 처리합니다.
public typealias AuthenticationInvalidationHandler = @Sendable () -> Void

/// 401 Unauthorized 에러 발생 시 Token을 자동으로 갱신하고 재시도하는 Retrier
/// - 401 에러 발생 시 Refresh Token으로 갱신 후 1번 재시도
/// - 여러 요청이 동시에 401을 받아도 토큰 갱신은 1번만 실행
public final class BearerTokenRetrier: RequestRetrier, @unchecked Sendable {
    private let tokenStorage: TokenStorage
    private let tokenRefresher: TokenRefreshHandler
    private let shouldInvalidateAuthentication: AuthenticationInvalidationEvaluator
    private let onAuthenticationInvalidated: AuthenticationInvalidationHandler
    private let logging: Bool
    private let queue = DispatchQueue(label: "com.chanetworking.tokenrefresh", qos: .utility)
    private var isRefreshing = false
    private var pendingRetries: [@Sendable (RetryResult) -> Void] = []
    private var authenticationIsInvalidated = false

    /// BearerTokenRetrier 초기화
    /// - Parameters:
    ///   - tokenStorage: Token 저장소 (기본값: KeychainTokenStorage)
    ///   - tokenRefresher: Token 갱신 로직을 구현한 클로저
    public init(
        tokenStorage: TokenStorage = KeychainTokenStorage(),
        tokenRefresher: @escaping TokenRefreshHandler,
        shouldInvalidateAuthentication: @escaping AuthenticationInvalidationEvaluator = { _ in false },
        onAuthenticationInvalidated: @escaping AuthenticationInvalidationHandler = {},
        logging: Bool = false
    ) {
        self.tokenStorage = tokenStorage
        self.tokenRefresher = tokenRefresher
        self.shouldInvalidateAuthentication = shouldInvalidateAuthentication
        self.onAuthenticationInvalidated = onAuthenticationInvalidated
        self.logging = logging
    }

    // MARK: - RequestRetrier

    public func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping @Sendable (RetryResult) -> Void
    ) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            completion(.doNotRetry)
            return
        }

        // doNotRetryWithError로 끝낸 실패가 response serializer에서 다시 전달되는 경우입니다.
        // 이미 refresh 또는 인증 무효화 처리를 마쳤으므로 중복 처리하지 않습니다.
        if let afError = error as? AFError,
           case .requestRetryFailed = afError {
            completion(.doNotRetry)
            return
        }

        let errorDescription = error.localizedDescription
        queue.async { [self] in
            if authenticationIsInvalidated,
               tokenStorage.getTokenPair() != nil {
                authenticationIsInvalidated = false
            }

            if request.retryCount > 0,
               authenticationIsInvalidated {
                completion(.doNotRetry)
                return
            }

            log(
                "Handling 401 for request \(request.id) "
                    + "(retryCount: \(request.retryCount), error: \(errorDescription))"
            )

            if request.retryCount > 0 {
                invalidateAuthentication(
                    reason: "Request was rejected again after token refresh."
                )
                completion(.doNotRetry)
                return
            }

            // 이미 refresh 중이면 큐에 추가
            self.pendingRetries.append(completion)

            guard !self.isRefreshing else {
                return
            }

            self.isRefreshing = true

            // Refresh Token 갱신 시작
            self.refreshTokens { [self] resolution in
                self.queue.async {
                    // 1. 먼저 대기 중인 요청들을 복사하고 배열 비우기
                    let pendingRetries = self.pendingRetries
                    self.pendingRetries.removeAll()

                    // 2. 그 다음 refresh 상태 해제 (새로운 refresh 사이클 허용)
                    // retry 시 다시 401을 return할 가능성이 있으므로 retry 시도 전 refresh 사이클을 미리 허용해 두어야 함
                    self.isRefreshing = false

                    // 3. 마지막으로 대기 중이던 요청들 처리
                    switch resolution {
                    case .retry:
                        self.authenticationIsInvalidated = false
                        pendingRetries.forEach { $0(.retry) }

                    case .fail(let error, let invalidatesAuthentication):
                        if invalidatesAuthentication {
                            self.invalidateAuthentication(
                                reason: error.localizedDescription
                            )
                        } else {
                            self.log(
                                "Token refresh failed temporarily: \(error.localizedDescription)"
                            )
                        }
                        pendingRetries.forEach { $0(.doNotRetryWithError(error)) }
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    private func refreshTokens(completion: @escaping (RefreshResolution) -> Void) {
        guard
            let refreshToken = tokenStorage.getTokenPair()?.refreshToken,
            refreshToken.isEmpty == false
        else {
            completion(
                .fail(
                    error: BearerAuthenticationError.missingRefreshToken,
                    invalidatesAuthentication: true
                )
            )
            return
        }

        // 사용자 제공 tokenRefresher 클로저 호출
        tokenRefresher(refreshToken) { [self] result in
            switch result {
            case .success(let tokens):
                // 새 토큰 저장
                do {
                    try self.tokenStorage.saveTokenPair(tokens)
                    self.log("Token refresh succeeded.")
                    completion(.retry)
                } catch {
                    completion(
                        .fail(
                            error: BearerAuthenticationError.tokenStorageFailed(error),
                            invalidatesAuthentication: true
                        )
                    )
                }

            case .failure(let error):
                completion(
                    .fail(
                        error: error,
                        invalidatesAuthentication: self.shouldInvalidateAuthentication(error)
                    )
                )
            }
        }
    }

    private func invalidateAuthentication(reason: String) {
        guard authenticationIsInvalidated == false else { return }
        authenticationIsInvalidated = true

        do {
            try tokenStorage.clearTokens()
        } catch {
            log("Failed to clear invalid token pair: \(error.localizedDescription)")
        }

        log("Authentication invalidated: \(reason)")
        onAuthenticationInvalidated()
    }

    private func log(_ message: String) {
        guard logging else { return }
        print("[ChaNetworkingSDK][BearerAuth] \(message)")
    }
}

private enum RefreshResolution: @unchecked Sendable {
    case retry
    case fail(error: any Error, invalidatesAuthentication: Bool)
}

private enum BearerAuthenticationError: LocalizedError {
    case missingRefreshToken
    case tokenStorageFailed(any Error)

    var errorDescription: String? {
        switch self {
        case .missingRefreshToken:
            return "Refresh token is missing."
        case .tokenStorageFailed(let error):
            return "Failed to store refreshed token pair: \(error.localizedDescription)"
        }
    }
}
