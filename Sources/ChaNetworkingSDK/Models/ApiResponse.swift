//
//  ApiResponse.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/10/25.
//

import Foundation

// MARK: - Response Wrapper
/// API 응답을 단일 구조로 캡슐화하여 제공하는 타입입니다.
/// - `value`: JSON 디코딩이 완료된 모델.
/// - `data`: 서버에서 전달된 원본 Raw Data (추가 파싱, 로깅 시 활용 가능).
/// - `httpResponse`: HTTP 상태 코드 및 헤더 등 메타정보.
/// 이 구조체를 사용하면 SDK 사용자는 응답 데이터에 대해 더 큰 유연성을 가질 수 있습니다.
public struct ApiResponse<Value> {
    public let value: Value
    public let data: Data
    public let httpResponse: HTTPURLResponse
}

// MARK: - Sendable
/// Value가 Sendable을 채택한 경우에만 ApiResponse도 Sendable이 됩니다. (조건부 채택)
/// 이를 통해 Swift Concurrency 환경(Task, Actor 간)에서 안전하게 전달할 수 있습니다.
/// Data와 HTTPURLResponse는 이미 Sendable이므로, Value만 Sendable이면 전체가 안전합니다.
extension ApiResponse: Sendable where Value: Sendable {}
