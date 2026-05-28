//
//  EndpointClient+ValueResponse.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Foundation
import Alamofire

/// `ApiResponse<T>` 대신 디코딩된 값 `T`를 직접 반환하는 편의 메서드입니다.
/// 타입 어노테이션으로 어떤 오버로드를 사용할지 컴파일러가 자동으로 결정합니다.
///
/// ```swift
/// // 값만 필요할 때
/// let user: User = try await client.get("/users/1")
///
/// // 상세 응답 정보가 필요할 때
/// let response: ApiResponse<User> = try await client.get("/users/1")
/// ```
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient where Self: NetworkClient {

    public func get<T: Decodable>(
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response: ApiResponse<T> = try await get(path, parameters: parameters, encoding: encoding, headers: headers, decoder: decoder)
        return response.value
    }

    public func post<T: Decodable>(
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response: ApiResponse<T> = try await post(path, parameters: parameters, encoding: encoding, headers: headers, decoder: decoder)
        return response.value
    }

    public func put<T: Decodable>(
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response: ApiResponse<T> = try await put(path, parameters: parameters, encoding: encoding, headers: headers, decoder: decoder)
        return response.value
    }

    public func patch<T: Decodable>(
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response: ApiResponse<T> = try await patch(path, parameters: parameters, encoding: encoding, headers: headers, decoder: decoder)
        return response.value
    }

    public func delete<T: Decodable>(
        _ path: String,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response: ApiResponse<T> = try await delete(path, parameters: parameters, encoding: encoding, headers: headers, decoder: decoder)
        return response.value
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient where Self: NetworkClient {

    public func get<T: Decodable, Query: Encodable & Sendable>(
        _ path: String,
        query: Query? = nil,
        encoder: ParameterEncoder = URLEncodedFormParameterEncoder.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response: ApiResponse<T> = try await get(path, query: query, encoder: encoder, headers: headers, decoder: decoder)
        return response.value
    }

    public func post<T: Decodable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body? = nil,
        encoder: ParameterEncoder = JSONParameterEncoder.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response: ApiResponse<T> = try await post(path, body: body, encoder: encoder, headers: headers, decoder: decoder)
        return response.value
    }

    public func put<T: Decodable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body? = nil,
        encoder: ParameterEncoder = JSONParameterEncoder.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response: ApiResponse<T> = try await put(path, body: body, encoder: encoder, headers: headers, decoder: decoder)
        return response.value
    }

    public func patch<T: Decodable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body? = nil,
        encoder: ParameterEncoder = JSONParameterEncoder.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response: ApiResponse<T> = try await patch(path, body: body, encoder: encoder, headers: headers, decoder: decoder)
        return response.value
    }

    public func delete<T: Decodable, Query: Encodable & Sendable>(
        _ path: String,
        query: Query? = nil,
        encoder: ParameterEncoder = URLEncodedFormParameterEncoder.default,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response: ApiResponse<T> = try await delete(path, query: query, encoder: encoder, headers: headers, decoder: decoder)
        return response.value
    }
}
