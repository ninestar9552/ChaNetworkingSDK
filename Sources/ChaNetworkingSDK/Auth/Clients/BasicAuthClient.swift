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
open class BasicAuthClient: NetworkClient, AuthenticatedClient {
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
}
