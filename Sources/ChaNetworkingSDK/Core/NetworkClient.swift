//
//  NetworkClient.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/10/25.
//

import Foundation
import Alamofire
import Combine

// MARK: - Network Client Core
/// `NetworkClient`는 모든 API 요청의 진입점입니다.
/// - `session`: Alamofire Session (ex: 인증옵션/인터셉터 포함)
/// - `encoding`: 디폴트 파라미터 인코딩 전략
/// - `errorHandler`: 에러 처리 전략 주입 가능 (사용자 커스텀 허용)
/// - `logging`: 요청/응답 로깅 활성화 여부
open class NetworkClient {
    public let session: Session
    public let encoding: ParameterEncoding
    public let errorHandler: NetworkErrorHandler
    public let logging: Bool

    public init(
        session: Session,
        encoding: ParameterEncoding = JSONEncoding(options: .prettyPrinted),
        errorHandler: NetworkErrorHandler = DefaultNetworkErrorHandler(),
        logging: Bool = false
    ) {
        self.session = session
        self.encoding = encoding
        self.errorHandler = errorHandler
        self.logging = logging
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension NetworkClient {
    /// API 요청을 수행하고 디코딩된 모델을 반환합니다. (Swift Concurrency 버전)
    /// - Returns:
    ///   `ApiResponse<T>` (값 + 원본 Data + HTTPURLResponse 제공)
    public func responseData<T: Codable>(
        _ httpMethod: Alamofire.HTTPMethod,
        _ url: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {

        var httpHeaders = HTTPHeaders(headers ?? [:])
        httpHeaders.update(.contentType("application/json"))
        httpHeaders.update(.accept("application/json"))

        let dataRequest: DataRequest = self.session.request(
            url,
            method: httpMethod,
            parameters: parameters,
            encoding: encoding ?? self.encoding,
            headers: httpHeaders
        )

        return try await dataRequest.serializedResponse(using: self, decoder: decoder)
    }

    /// API 요청을 수행하고 디코딩된 모델을 반환합니다. (Encodable 파라미터 버전)
    /// - Parameters:
    ///   - httpMethod: HTTP 메서드
    ///   - url: 요청 URL
    ///   - parameters: Encodable 파라미터
    ///   - encoder: ParameterEncoder (URLEncodedFormParameterEncoder 또는 JSONParameterEncoder)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    /// - Returns: `ApiResponse<T>`
    public func responseData<T: Codable, P: Encodable & Sendable>(
        _ httpMethod: Alamofire.HTTPMethod,
        _ url: String,
        parameters: P?,
        encoder: ParameterEncoder,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {

        var httpHeaders = HTTPHeaders(headers ?? [:])
        httpHeaders.update(.contentType("application/json"))
        httpHeaders.update(.accept("application/json"))

        let dataRequest: DataRequest = self.session.request(
            url,
            method: httpMethod,
            parameters: parameters,
            encoder: encoder,
            headers: httpHeaders
        )

        return try await dataRequest.serializedResponse(using: self, decoder: decoder)
    }



    /// API 요청을 수행하고 디코딩된 모델을 반환합니다.
    ///
    /// - Parameters:
    ///   - httpMethod: GET / POST 등 HTTP 메서드
    ///   - url: 요청 URL 문자열
    ///   - parameters: Request Body 또는 Query Parameters
    ///   - encoding: 파라미터 인코딩 전략 (기본값: JSONEncoding)
    ///   - headers: 추가 Header 값
    ///   - decoder: JSONDecoder (기본값: JSONDecoder())
    ///
    /// - Returns:
    ///   Combine `AnyPublisher<ApiResponse<T>, Error>`
    ///
    /// 서비스 앱에서 사용 예:
    /// ```
    /// client.responseData(.get, "/users")
    ///     .sink(receiveCompletion: ..., receiveValue: { response in
    ///         print(response.value)
    ///     })
    /// ```
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    public func responseDataPublisher<T: Codable>(
        _ httpMethod: Alamofire.HTTPMethod,
        _ url: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    )-> AnyPublisher<ApiResponse<T>, Error> {

        var httpHeaders = HTTPHeaders(headers ?? [:])
        httpHeaders.update(HTTPHeader.contentType("application/json"))
        httpHeaders.update(HTTPHeader.accept("application/json"))

        let dataRequest: DataRequest = self.session.request(
            url,
            method: httpMethod,
            parameters: parameters,
            encoding: encoding ?? self.encoding,
            headers: httpHeaders
        )

        return dataRequest.publish(using: self, decoder: decoder)
    }

    /// API 요청을 수행하고 디코딩된 모델을 반환합니다. (Encodable 파라미터 + Combine 버전)
    /// - Parameters:
    ///   - httpMethod: HTTP 메서드
    ///   - url: 요청 URL
    ///   - parameters: Encodable 파라미터
    ///   - encoder: ParameterEncoder (URLEncodedFormParameterEncoder 또는 JSONParameterEncoder)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    /// - Returns: `AnyPublisher<ApiResponse<T>, Error>`
    public func responseDataPublisher<T: Codable, P: Encodable & Sendable>(
        _ httpMethod: Alamofire.HTTPMethod,
        _ url: String,
        parameters: P?,
        encoder: ParameterEncoder,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<ApiResponse<T>, Error> {

        var httpHeaders = HTTPHeaders(headers ?? [:])
        httpHeaders.update(HTTPHeader.contentType("application/json"))
        httpHeaders.update(HTTPHeader.accept("application/json"))

        let dataRequest: DataRequest = self.session.request(
            url,
            method: httpMethod,
            parameters: parameters,
            encoder: encoder,
            headers: httpHeaders
        )

        return dataRequest.publish(using: self, decoder: decoder)
    }
}
