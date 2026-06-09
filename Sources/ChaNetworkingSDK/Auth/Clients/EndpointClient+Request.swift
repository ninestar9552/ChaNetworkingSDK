//
//  EndpointClient+Request.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Foundation
import Alamofire

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient where Self: NetworkClient {

    /// API 요청 (async/await) - `Parameters` 딕셔너리와 `ParameterEncoding` 사용
    /// - Parameters:
    ///   - httpMethod: HTTP 메서드
    ///   - path: API 경로 (예: "/users/me")
    ///   - parameters: 요청 파라미터 딕셔너리
    ///   - encoding: 파라미터 인코딩 (nil이면 클라이언트 기본 인코딩 사용)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func request<T: Decodable>(
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

    /// GET 요청 - 리소스 조회
    /// - Parameters:
    ///   - path: API 경로 (예: "/users/me")
    ///   - parameters: 요청 파라미터 딕셔너리
    ///   - encoding: 파라미터 인코딩 (기본: URL 인코딩)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func get<T: Decodable>(
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        return try await request(
            .get,
            path,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            decoder: decoder
        )
    }

    /// POST 요청 - 리소스 생성
    /// - Parameters:
    ///   - path: API 경로
    ///   - parameters: 요청 파라미터 딕셔너리
    ///   - encoding: 파라미터 인코딩 (기본: JSON)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func post<T: Decodable>(
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
    ///   - parameters: 요청 파라미터 딕셔너리
    ///   - encoding: 파라미터 인코딩 (기본: JSON)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func put<T: Decodable>(
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
    ///   - parameters: 요청 파라미터 딕셔너리
    ///   - encoding: 파라미터 인코딩 (기본: JSON)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func patch<T: Decodable>(
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
    ///   - parameters: 요청 파라미터 딕셔너리
    ///   - encoding: 파라미터 인코딩 (기본: URL 인코딩)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func delete<T: Decodable>(
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        return try await request(
            .delete,
            path,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            decoder: decoder
        )
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient where Self: NetworkClient {

    /// API 요청 (async/await) - `Encodable` 파라미터와 `ParameterEncoder` 사용
    /// - Parameters:
    ///   - httpMethod: HTTP 메서드
    ///   - path: API 경로 (예: "/users/me")
    ///   - parameters: Encodable 요청 모델
    ///   - encoder: 파라미터 인코더
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func request<T: Decodable, RequestParameters: Encodable & Sendable>(
        _ httpMethod: Alamofire.HTTPMethod,
        _ path: String,
        parameters: RequestParameters?,
        encoder: ParameterEncoder,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        let fullURL = buildURL(path: path)
        return try await responseData(
            httpMethod,
            fullURL,
            parameters: parameters,
            encoder: encoder,
            headers: headers,
            decoder: decoder
        )
    }

    /// GET 요청 - Encodable 요청 모델
    /// - Parameters:
    ///   - path: API 경로 (예: "/users")
    ///   - query: Encodable 요청 모델
    ///   - encoder: 파라미터 인코더 (기본: URL form)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func get<T: Decodable, Query: Encodable & Sendable>(
        _ path: String,
        query: Query?,
        encoder: ParameterEncoder = URLEncodedFormParameterEncoder.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        return try await request(
            .get,
            path,
            parameters: query,
            encoder: encoder,
            headers: headers,
            decoder: decoder
        )
    }

    /// POST 요청 - Encodable 요청 모델
    /// - Parameters:
    ///   - path: API 경로
    ///   - body: Encodable 요청 모델
    ///   - encoder: 파라미터 인코더 (기본: JSON)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func post<T: Decodable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body?,
        encoder: ParameterEncoder = JSONParameterEncoder.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        return try await request(
            .post,
            path,
            parameters: body,
            encoder: encoder,
            headers: headers,
            decoder: decoder
        )
    }

    /// PUT 요청 - Encodable 요청 모델
    /// - Parameters:
    ///   - path: API 경로
    ///   - body: Encodable 요청 모델
    ///   - encoder: 파라미터 인코더 (기본: JSON)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func put<T: Decodable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body?,
        encoder: ParameterEncoder = JSONParameterEncoder.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        return try await request(
            .put,
            path,
            parameters: body,
            encoder: encoder,
            headers: headers,
            decoder: decoder
        )
    }

    /// PATCH 요청 - Encodable 요청 모델
    /// - Parameters:
    ///   - path: API 경로
    ///   - body: Encodable 요청 모델
    ///   - encoder: 파라미터 인코더 (기본: JSON)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func patch<T: Decodable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body?,
        encoder: ParameterEncoder = JSONParameterEncoder.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        return try await request(
            .patch,
            path,
            parameters: body,
            encoder: encoder,
            headers: headers,
            decoder: decoder
        )
    }

    /// DELETE 요청 - Encodable 요청 모델
    /// - Parameters:
    ///   - path: API 경로
    ///   - query: Encodable 요청 모델
    ///   - encoder: 파라미터 인코더 (기본: URL form)
    ///   - headers: 추가 헤더
    ///   - decoder: JSON 디코더
    public func delete<T: Decodable, Query: Encodable & Sendable>(
        _ path: String,
        query: Query?,
        encoder: ParameterEncoder = URLEncodedFormParameterEncoder.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> ApiResponse<T> {
        return try await request(
            .delete,
            path,
            parameters: query,
            encoder: encoder,
            headers: headers,
            decoder: decoder
        )
    }
}
