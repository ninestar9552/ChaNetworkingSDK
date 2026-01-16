//
//  BearerTokenClient+Convenience.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Foundation
import Alamofire
import Combine

// MARK: - Convenience Methods (async/await)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension BearerTokenClient {
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
            encoding: URLEncoding.default,  // GET은 URL encoding
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
            encoding: URLEncoding.default,  // DELETE는 URL encoding
            headers: headers,
            decoder: decoder
        )
    }
}

// MARK: - Convenience Methods (Combine)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension BearerTokenClient {
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
