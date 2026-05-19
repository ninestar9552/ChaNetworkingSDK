//
//  EmptyPayload.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Foundation

/// Request 또는 response body가 없는 API를 표현하기 위한 빈 payload 타입입니다.
///
/// 일반적으로 다음 경우에 사용됩니다:
/// - `204 No Content` 응답
/// - `DELETE` 요청 (리소스 삭제)
/// - `PUT` 요청 (업데이트만 하고 응답 없음)
///
/// 사용 예:
/// ```swift
/// // DELETE 요청
/// let response: ApiResponse<EmptyPayload> = try await client.delete("/users/1")
/// print(response.httpResponse.statusCode)  // 204
///
/// // PUT 요청 (응답 없음)
/// let response: ApiResponse<EmptyPayload> = try await client.put("/users/1/activate")
/// ```
public struct EmptyPayload: Codable, Equatable, Sendable {
    /// 빈 payload 초기화
    public init() {}
    // 프로퍼티가 없는 struct는 Swift가 Equatable을 자동 합성합니다.
}
