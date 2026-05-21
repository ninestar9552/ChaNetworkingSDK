//
//  EndpointClient.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Foundation

/// baseURL을 기반으로 상대 경로 요청을 지원하는 클라이언트 프로토콜
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public protocol EndpointClient: AnyObject {
    /// API Base URL (예: "https://api.example.com")
    var baseURL: String { get }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EndpointClient {
    /// 상대 경로를 전체 URL로 변환
    /// - Parameter path: API 경로 (예: "/users/me" 또는 전체 URL)
    /// - Returns: 전체 URL 문자열
    public func buildURL(path: String) -> String {
        if path.starts(with: "http://") || path.starts(with: "https://") {
            return path
        }

        let base = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
        return base + cleanPath
    }
}
