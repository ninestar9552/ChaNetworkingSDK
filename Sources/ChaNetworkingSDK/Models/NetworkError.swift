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
public enum NetworkError: Error {
    case noResponse
    case noData
    case decodingFailed(Error)
    case serverError(statusCode: Int, message: String?)
    case underlying(Error)
}
