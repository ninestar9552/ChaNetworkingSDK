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
        guard let data = data else { return NetworkError.noData }

        if !(200..<300).contains(response.statusCode) {
            let message = String(data: data, encoding: .utf8)
            return NetworkError.serverError(statusCode: response.statusCode, message: message)
        }

        return nil
    }
}
