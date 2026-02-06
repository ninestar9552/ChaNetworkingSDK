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

/// non-Sendable 값을 @Sendable 클로저에서 안전하게 전달하기 위한 래퍼
///
/// `DispatchQueue.async`는 `@Sendable` 클로저를 요구하지만,
/// Alamofire의 `RequestRetrier` 프로토콜이 제공하는 `completion`과 `error`는
/// `Sendable`을 채택하지 않습니다.
/// 직렬 큐(serial queue)를 통해 동기화가 보장되므로 `@unchecked Sendable`로 안전하게 래핑합니다.
private struct UncheckedSendableBox<T>: @unchecked Sendable {
    let value: T
}

/// 401 Unauthorized 에러 발생 시 Token을 자동으로 갱신하고 재시도하는 Retrier
/// - 401 에러 발생 시 Refresh Token으로 갱신 후 1번 재시도
/// - 여러 요청이 동시에 401을 받아도 토큰 갱신은 1번만 실행
public final class BearerTokenRetrier: RequestRetrier, @unchecked Sendable {
    private let tokenStorage: TokenStorage
    private let tokenRefresher: TokenRefreshHandler
    private let queue = DispatchQueue(label: "com.chanetworking.tokenrefresh", qos: .utility)
    private var isRefreshing = false
    private var requestsToRetry: [(RetryResult) -> Void] = []

    /// BearerTokenRetrier 초기화
    /// - Parameters:
    ///   - tokenStorage: Token 저장소 (기본값: KeychainTokenStorage)
    ///   - tokenRefresher: Token 갱신 로직을 구현한 클로저
    public init(
        tokenStorage: TokenStorage = KeychainTokenStorage(),
        tokenRefresher: @escaping TokenRefreshHandler
    ) {
        self.tokenStorage = tokenStorage
        self.tokenRefresher = tokenRefresher
    }

    // MARK: - RequestRetrier

    public func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401,
              request.retryCount == 0 else {
            // 401이 아니거나 이미 재시도했으면 재시도하지 않음
            completion(.doNotRetryWithError(error))
            return
        }

        // Alamofire의 RequestRetrier 프로토콜이 제공하는 completion과 error는
        // Sendable을 채택하지 않으므로 @Sendable 클로저(queue.async)에 직접 캡처할 수 없습니다.
        // 직렬 큐로 동기화가 보장되므로 UncheckedSendableBox로 안전하게 래핑합니다.
        let sendableCompletion = UncheckedSendableBox(value: completion)
        let sendableError = UncheckedSendableBox(value: error)

        queue.async { [weak self] in
            guard let self = self else { return }

            // 이미 refresh 중이면 큐에 추가
            self.requestsToRetry.append(sendableCompletion.value)

            guard !self.isRefreshing else {
                return
            }

            self.isRefreshing = true

            // Refresh Token 갱신 시작
            self.refreshTokens { [weak self] succeeded in
                guard let self = self else { return }

                self.queue.async {
                    // 1. 먼저 대기 중인 요청들을 복사하고 배열 비우기
                    let retriers = self.requestsToRetry
                    self.requestsToRetry.removeAll()

                    // 2. 그 다음 refresh 상태 해제 (새로운 refresh 사이클 허용)
                    // retry 시 다시 401을 return할 가능성이 있으므로 retry 시도 전 refresh 사이클을 미리 허용해 두어야 함
                    self.isRefreshing = false

                    // 3. 마지막으로 대기 중이던 요청들 처리
                    if succeeded {
                        // 성공: 모든 대기 중인 요청 재시도
                        retriers.forEach { $0(.retry) }
                    } else {
                        // 실패: 모든 요청 실패 처리
                        retriers.forEach { $0(.doNotRetryWithError(sendableError.value)) }
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    private func refreshTokens(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = tokenStorage.getRefreshToken() else {
            completion(false)
            return
        }

        // 사용자 제공 tokenRefresher 클로저 호출
        tokenRefresher(refreshToken) { [weak self] result in
            guard let self = self else {
                completion(false)
                return
            }

            switch result {
            case .success(let tokens):
                // 새 토큰 저장
                do {
                    try self.tokenStorage.saveAccessToken(tokens.accessToken)
                    try self.tokenStorage.saveRefreshToken(tokens.refreshToken)
                    completion(true)
                } catch {
                    completion(false)
                }

            case .failure:
                completion(false)
            }
        }
    }
}
