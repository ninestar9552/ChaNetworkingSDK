//
//  NetworkErrorHandler.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/10/25.
//

import Foundation
import Alamofire

// MARK: - Error Handling Strategy
/// 서비스 앱에서 자체적인 에러 처리 규칙을 적용할 수 있도록 제공되는 프로토콜입니다.
/// 예: 401 에러 시 자동 로그아웃, 500 에러 시 사용자 알림 등
public protocol NetworkErrorHandler {
    func transform(response: HTTPURLResponse?, data: Data?, error: AFError?) -> Error?
}
