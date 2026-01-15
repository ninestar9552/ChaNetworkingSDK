//
//  EmptyResponse.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Foundation

/// Response body가 없는 API 응답을 위한 빈 타입
///
/// 일반적으로 다음 경우에 사용됩니다:
/// - `204 No Content` 응답
/// - `DELETE` 요청 (리소스 삭제)
/// - `PUT` 요청 (업데이트만 하고 응답 없음)
///
/// 사용 예:
/// ```swift
/// // DELETE 요청
/// let response: ApiResponse<EmptyResponse> = try await client.delete("/users/1")
/// print(response.httpResponse.statusCode)  // 204
///
/// // PUT 요청 (응답 없음)
/// let response: ApiResponse<EmptyResponse> = try await client.put("/users/1/activate")
/// ```
public struct EmptyResponse: Codable, Equatable {
    /// 빈 응답 초기화
    public init() {}

    public static func == (lhs: EmptyResponse, rhs: EmptyResponse) -> Bool {
        return true  // 모든 EmptyResponse는 동일
    }
}
