//
//  NetworkError.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/10/25.
//

import Foundation

// MARK: - Error Types
/// 네트워크 계층에서 발생 가능한 오류를 통합적으로 표현하는 타입.
/// 서비스 앱은 이 타입만 신경 쓰면 되므로 SDK 내부 오류 처리 세부사항에 의존하지 않아도 됩니다.
///
/// `LocalizedError`를 채택하여 `error.localizedDescription`으로
/// 사용자에게 의미 있는 에러 메시지를 제공합니다.
public enum NetworkError: Error, LocalizedError {
    case noResponse
    case noData
    case decodingFailed(Error)
    case serverError(statusCode: Int, message: String?)
    case underlying(Error)

    public var errorDescription: String? {
        switch self {
        case .noResponse:
            return "No response received from server"
        case .noData:
            return "Response data is empty"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Server error [\(statusCode)]: \(message ?? "Unknown error")"
        case .underlying(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
