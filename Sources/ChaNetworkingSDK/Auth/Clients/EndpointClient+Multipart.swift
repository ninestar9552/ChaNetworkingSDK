//
//  EndpointClient+Multipart.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Foundation
import Alamofire

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient where Self: NetworkClient {

    /// multipart/form-data 업로드 요청입니다.
    public func uploadMultipart<T: Decodable>(
        _ path: String,
        method: Alamofire.HTTPMethod = .post,
        fields: [MultipartField] = [],
        files: [MultipartFile] = [],
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder(),
        progress: (@Sendable (Progress) -> Void)? = nil
    ) async throws -> ApiResponse<T> {
        try await (self as NetworkClient).uploadMultipart(
            to: buildURL(path: path),
            method: method,
            fields: fields,
            files: files,
            headers: headers,
            decoder: decoder,
            progress: progress
        )
    }

    /// multipart/form-data 업로드 요청 후 디코딩된 값만 반환합니다.
    public func uploadMultipart<T: Decodable>(
        _ path: String,
        method: Alamofire.HTTPMethod = .post,
        fields: [MultipartField] = [],
        files: [MultipartFile] = [],
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder(),
        progress: (@Sendable (Progress) -> Void)? = nil
    ) async throws -> T {
        let response: ApiResponse<T> = try await uploadMultipart(
            path,
            method: method,
            fields: fields,
            files: files,
            headers: headers,
            decoder: decoder,
            progress: progress
        )
        return response.value
    }
}
