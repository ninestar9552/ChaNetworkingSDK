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
