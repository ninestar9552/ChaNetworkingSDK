//
//  BasicAuthClient.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/14/25.
//

import Foundation
import Alamofire
import Combine

/// Basic Authentication을 사용하는 Network Client
/// - 자동으로 모든 요청에 Basic Auth 헤더 추가
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
open class BasicAuthClient: NetworkClient {
    public let baseURL: String

    /// BasicAuthClient 초기화
    /// - Parameters:
    ///   - baseURL: API Base URL (예: "https://api.example.com")
    ///   - configuration: URLSession configuration (기본값: .default)
    ///   - username: 사용자 이름
    ///   - password: 비밀번호
    ///   - encoding: 파라미터 인코딩 전략 (기본값: JSONEncoding)
    ///   - errorHandler: 에러 핸들러 (기본값: DefaultNetworkErrorHandler)
    ///   - logging: 로깅 활성화 여부 (기본값: false)
    public init(
        baseURL: String,
        configuration: URLSessionConfiguration = .default,
        username: String,
        password: String,
        encoding: ParameterEncoding = JSONEncoding(options: .prettyPrinted),
        errorHandler: NetworkErrorHandler = DefaultNetworkErrorHandler(),
        logging: Bool = false
    ) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL

        // BasicAuthAdapter 생성
        let adapter = BasicAuthAdapter(username: username, password: password)

        // Session with Interceptor 생성
        let session = Session(
            configuration: configuration,
            interceptor: adapter
        )

        super.init(
            session: session,
            encoding: encoding,
            errorHandler: errorHandler,
            logging: logging
        )
    }

    // MARK: - Convenience Methods

    /// API 요청 (async/await) - 상대 경로 자동 결합
    /// - Parameters:
    ///   - httpMethod: HTTP 메서드
    ///   - path: API 경로 (예: "/users")
    ///   - parameters: 요청 파라미터
    ///   - encoding: 파라미터 인코딩 (기본값: 클라이언트 설정)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func request<T: Codable>(
        _ httpMethod: Alamofire.HTTPMethod,
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        let fullURL = buildURL(path: path)
        return try await responseData(
            httpMethod,
            fullURL,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            decoder: decoder
        )
    }

    /// API 요청 (Combine) - 상대 경로 자동 결합
    public func requestPublisher<T: Codable>(
        _ httpMethod: Alamofire.HTTPMethod,
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<ApiResponse<T>, Error> {
        let fullURL = buildURL(path: path)
        return responseDataPublisher(
            httpMethod,
            fullURL,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            decoder: decoder
        )
    }

    // MARK: - Private Helpers
    private func buildURL(path: String) -> String {
        if path.starts(with: "http://") || path.starts(with: "https://") {
            return path
        }
        let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
        return baseURL + cleanPath
    }
}
