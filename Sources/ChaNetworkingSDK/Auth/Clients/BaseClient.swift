//
//  BaseClient.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Foundation
import Alamofire
import Combine

/// 인증 없이 baseURL을 사용하는 기본 Network Client
/// - 상대 경로로 API 호출 가능
/// - 인증이 필요 없는 공개 API에 적합
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
open class BaseClient: NetworkClient, AuthenticatedClient {
    public let baseURL: String

    /// BaseClient 초기화
    /// - Parameters:
    ///   - baseURL: API Base URL (예: "https://api.example.com")
    ///   - configuration: URLSession configuration (기본값: .default)
    ///   - encoding: 파라미터 인코딩 전략 (기본값: JSONEncoding)
    ///   - errorHandler: 에러 핸들러 (기본값: DefaultNetworkErrorHandler)
    ///   - logging: 로깅 활성화 여부 (기본값: false)
    public init(
        baseURL: String,
        configuration: URLSessionConfiguration = .default,
        encoding: ParameterEncoding = JSONEncoding(options: .prettyPrinted),
        errorHandler: NetworkErrorHandler = DefaultNetworkErrorHandler(),
        logging: Bool = false
    ) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL

        let session = Session(configuration: configuration)

        super.init(
            session: session,
            encoding: encoding,
            errorHandler: errorHandler,
            logging: logging
        )
    }
}
