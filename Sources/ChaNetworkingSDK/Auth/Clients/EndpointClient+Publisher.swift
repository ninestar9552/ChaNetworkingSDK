//
//  EndpointClient+Publisher.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Foundation
import Alamofire
import Combine

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient where Self: NetworkClient {

    /// API 요청 (Combine) - 상대 경로 자동 결합
    public func requestPublisher<T: Decodable>(
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

    /// GET 요청 Publisher - 리소스 조회
    public func getPublisher<T: Decodable>(
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
    public func postPublisher<T: Decodable>(
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
    public func putPublisher<T: Decodable>(
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
    public func patchPublisher<T: Decodable>(
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
    public func deletePublisher<T: Decodable>(
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

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient where Self: NetworkClient {

    /// GET 요청 Publisher - Encodable 쿼리 파라미터
    public func getPublisher<T: Decodable, Query: Encodable & Sendable>(
        _ path: String,
        query: Query?,
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
    public func postPublisher<T: Decodable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body?,
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
    public func putPublisher<T: Decodable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body?,
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
    public func patchPublisher<T: Decodable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body?,
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
    public func deletePublisher<T: Decodable, Query: Encodable & Sendable>(
        _ path: String,
        query: Query?,
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
