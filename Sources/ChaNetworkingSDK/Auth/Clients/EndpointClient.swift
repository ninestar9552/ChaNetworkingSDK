//
//  EndpointClient.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Foundation
import Alamofire
import Combine

// MARK: - Protocol 정의

/// baseURL을 기반으로 상대 경로 요청을 지원하는 클라이언트 프로토콜
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public protocol EndpointClient: AnyObject {
    /// API Base URL (예: "https://api.example.com")
    var baseURL: String { get }
}

// MARK: - URL Building

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient {
    /// 상대 경로를 전체 URL로 변환
    /// - Parameter path: API 경로 (예: "/users/me" 또는 전체 URL)
    /// - Returns: 전체 URL 문자열
    public func buildURL(path: String) -> String {
        if path.starts(with: "http://") || path.starts(with: "https://") {
            return path
        }
        let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
        return baseURL + cleanPath
    }
}

// MARK: - Core Request Methods (NetworkClient 상속 시)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient where Self: NetworkClient {

    /// API 요청 (async/await) - 상대 경로 자동 결합
    /// - Parameters:
    ///   - httpMethod: HTTP 메서드
    ///   - path: API 경로 (예: "/users/me")
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
}

// MARK: - Convenience Methods (async/await)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient where Self: NetworkClient {

    /// GET 요청 - 리소스 조회
    /// - Parameters:
    ///   - path: API 경로 (예: "/users/me")
    ///   - parameters: Query parameters (URL에 추가됨)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func get<T: Codable>(
        _ path: String,
        parameters: Parameters? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        return try await request(
            .get,
            path,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: headers,
            decoder: decoder
        )
    }

    /// POST 요청 - 리소스 생성
    /// - Parameters:
    ///   - path: API 경로
    ///   - parameters: Request body
    ///   - encoding: 파라미터 인코딩 (기본: JSON)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func post<T: Codable>(
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        return try await request(
            .post,
            path,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            decoder: decoder
        )
    }

    /// PUT 요청 - 리소스 전체 수정
    /// - Parameters:
    ///   - path: API 경로
    ///   - parameters: Request body
    ///   - encoding: 파라미터 인코딩 (기본: JSON)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func put<T: Codable>(
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        return try await request(
            .put,
            path,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            decoder: decoder
        )
    }

    /// PATCH 요청 - 리소스 부분 수정
    /// - Parameters:
    ///   - path: API 경로
    ///   - parameters: Request body
    ///   - encoding: 파라미터 인코딩 (기본: JSON)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func patch<T: Codable>(
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        return try await request(
            .patch,
            path,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            decoder: decoder
        )
    }

    /// DELETE 요청 - 리소스 삭제
    /// - Parameters:
    ///   - path: API 경로
    ///   - parameters: Query parameters (선택)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func delete<T: Codable>(
        _ path: String,
        parameters: Parameters? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        return try await request(
            .delete,
            path,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: headers,
            decoder: decoder
        )
    }
}

// MARK: - Convenience Methods (Combine)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient where Self: NetworkClient {

    /// GET 요청 Publisher - 리소스 조회
    public func getPublisher<T: Codable>(
        _ path: String,
        parameters: Parameters? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<ApiResponse<T>, Error> {
        return requestPublisher(
            .get,
            path,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: headers,
            decoder: decoder
        )
    }

    /// POST 요청 Publisher - 리소스 생성
    public func postPublisher<T: Codable>(
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<ApiResponse<T>, Error> {
        return requestPublisher(
            .post,
            path,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            decoder: decoder
        )
    }

    /// PUT 요청 Publisher - 리소스 전체 수정
    public func putPublisher<T: Codable>(
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<ApiResponse<T>, Error> {
        return requestPublisher(
            .put,
            path,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            decoder: decoder
        )
    }

    /// PATCH 요청 Publisher - 리소스 부분 수정
    public func patchPublisher<T: Codable>(
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<ApiResponse<T>, Error> {
        return requestPublisher(
            .patch,
            path,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            decoder: decoder
        )
    }

    /// DELETE 요청 Publisher - 리소스 삭제
    public func deletePublisher<T: Codable>(
        _ path: String,
        parameters: Parameters? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<ApiResponse<T>, Error> {
        return requestPublisher(
            .delete,
            path,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: headers,
            decoder: decoder
        )
    }
}

// MARK: - Convenience Methods with Encodable (async/await)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient where Self: NetworkClient {

    /// GET 요청 - Encodable 쿼리 파라미터
    /// - Parameters:
    ///   - path: API 경로 (예: "/users")
    ///   - query: Encodable 쿼리 파라미터 (URL에 추가됨)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func get<T: Codable, Query: Encodable & Sendable>(
        _ path: String,
        query: Query? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        let fullURL = buildURL(path: path)
        return try await responseData(
            .get,
            fullURL,
            parameters: query,
            encoder: URLEncodedFormParameterEncoder.default,
            headers: headers,
            decoder: decoder
        )
    }

    /// POST 요청 - Encodable body
    /// - Parameters:
    ///   - path: API 경로
    ///   - body: Encodable request body
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func post<T: Codable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        let fullURL = buildURL(path: path)
        return try await responseData(
            .post,
            fullURL,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: headers,
            decoder: decoder
        )
    }

    /// PUT 요청 - Encodable body
    /// - Parameters:
    ///   - path: API 경로
    ///   - body: Encodable request body
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func put<T: Codable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        let fullURL = buildURL(path: path)
        return try await responseData(
            .put,
            fullURL,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: headers,
            decoder: decoder
        )
    }

    /// PATCH 요청 - Encodable body
    /// - Parameters:
    ///   - path: API 경로
    ///   - body: Encodable request body
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func patch<T: Codable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        let fullURL = buildURL(path: path)
        return try await responseData(
            .patch,
            fullURL,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: headers,
            decoder: decoder
        )
    }

    /// DELETE 요청 - Encodable 쿼리 파라미터
    /// - Parameters:
    ///   - path: API 경로
    ///   - query: Encodable 쿼리 파라미터 (URL에 추가됨)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func delete<T: Codable, Query: Encodable & Sendable>(
        _ path: String,
        query: Query? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        let fullURL = buildURL(path: path)
        return try await responseData(
            .delete,
            fullURL,
            parameters: query,
            encoder: URLEncodedFormParameterEncoder.default,
            headers: headers,
            decoder: decoder
        )
    }
}

// MARK: - Convenience Methods with Encodable (Combine)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient where Self: NetworkClient {

    /// GET 요청 Publisher - Encodable 쿼리 파라미터
    public func getPublisher<T: Codable, Query: Encodable & Sendable>(
        _ path: String,
        query: Query? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<ApiResponse<T>, Error> {
        let fullURL = buildURL(path: path)
        return responseDataPublisher(
            .get,
            fullURL,
            parameters: query,
            encoder: URLEncodedFormParameterEncoder.default,
            headers: headers,
            decoder: decoder
        )
    }

    /// POST 요청 Publisher - Encodable body
    public func postPublisher<T: Codable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<ApiResponse<T>, Error> {
        let fullURL = buildURL(path: path)
        return responseDataPublisher(
            .post,
            fullURL,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: headers,
            decoder: decoder
        )
    }

    /// PUT 요청 Publisher - Encodable body
    public func putPublisher<T: Codable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<ApiResponse<T>, Error> {
        let fullURL = buildURL(path: path)
        return responseDataPublisher(
            .put,
            fullURL,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: headers,
            decoder: decoder
        )
    }

    /// PATCH 요청 Publisher - Encodable body
    public func patchPublisher<T: Codable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<ApiResponse<T>, Error> {
        let fullURL = buildURL(path: path)
        return responseDataPublisher(
            .patch,
            fullURL,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: headers,
            decoder: decoder
        )
    }

    /// DELETE 요청 Publisher - Encodable 쿼리 파라미터
    public func deletePublisher<T: Codable, Query: Encodable & Sendable>(
        _ path: String,
        query: Query? = nil,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<ApiResponse<T>, Error> {
        let fullURL = buildURL(path: path)
        return responseDataPublisher(
            .delete,
            fullURL,
            parameters: query,
            encoder: URLEncodedFormParameterEncoder.default,
            headers: headers,
            decoder: decoder
        )
    }
}
