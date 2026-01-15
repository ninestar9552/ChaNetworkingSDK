//
//  DefaultNetworkErrorHandler.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/10/25.
//

import Foundation
import Alamofire

// MARK: - 기본 에러 처리 구현
/// SDK 기본 제공 오류 처리 전략입니다.
/// 필요 시 서비스 앱은 `NetworkClient` 초기화 시 custom handler를 주입하여 정책을 덮어쓸 수 있습니다.
public struct DefaultNetworkErrorHandler: NetworkErrorHandler {
    public init() {}

    public func transform(response: HTTPURLResponse?, data: Data?, error: AFError?) -> Error? {
        if let error = error { return NetworkError.underlying(error) }
        guard let response = response else { return NetworkError.noResponse }

        // 성공 응답
        if (200..<300).contains(response.statusCode) {
            return nil
        }

        // 실패 응답인 경우 statusCode 우선 반환 (message는 optional)
        let message = data.flatMap { String(data: $0, encoding: .utf8) }
        return NetworkError.serverError(statusCode: response.statusCode, message: message)
    }
}
