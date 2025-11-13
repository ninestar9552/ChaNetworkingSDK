//
//  DataRequest+Response.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/10/25.
//

import Foundation
import Alamofire
import Combine

extension DataRequest {
    internal func processResponse<T: Codable>(
        _ dataResponse: DataResponse<Data, AFError>,
        decoder: JSONDecoder,
        errorHandler: NetworkErrorHandler
    ) throws -> ApiResponse<T> {
        // ErrorHandler: 서비스 앱에서 커스텀 가능하도록 열어둠
        if let transformedError = errorHandler.transform(
            response: dataResponse.response,
            data: dataResponse.data,
            error: dataResponse.error
        ) {
            throw transformedError
        }

        // transform()이 response/data nil을 커버하지 않을 가능성을 대비 (Fail-safe)
        guard let httpResponse = dataResponse.response else { throw NetworkError.noResponse }
        guard let data = dataResponse.data else { throw NetworkError.noData }

        do {
            let decodedValue = try decoder.decode(T.self, from: data)
            return ApiResponse(value: decodedValue, data: data, httpResponse: httpResponse)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    /// Alamofire 요청을 Swift Concurrency 기반으로 수행합니다.
    ///
    /// - 처리 순서:
    ///   1. 요청/응답 로깅 출력 (옵션)
    ///   2. ErrorHandler를 통한 오류 변환 (서비스 앱 커스텀 정책 반영 가능)
    ///   3. response/data nil-safe 검사 (Fail-safe)
    ///   4. JSON 디코딩
    ///
    /// - 주의:
    ///   ErrorHandler가 커스텀된 경우 `transform()`에서 nil을 반환할 수 있으므로
    ///   아래에서 `response` / `data` 유효성 검사를 **한 번 더 수행**합니다.
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    internal func serializedResponse<T: Codable>(
        using client: NetworkClient,
        decoder: JSONDecoder,
        logging: Bool
    ) async throws -> ApiResponse<T> {

        let dataResponse = await self.serializingData().response

        self.log(dataResponse: dataResponse, logging: logging)

        return try self.processResponse(dataResponse, decoder: decoder, errorHandler: client.errorHandler)
    }

    /// Alamofire 요청을 Combine Publisher로 변환하여 반환합니다.
    ///
    /// - 처리 순서:
    ///   1. 요청/응답 로깅 출력 (옵션)
    ///   2. ErrorHandler를 통한 오류 변환
    ///   3. response/data nil-safe 검사 (Fail-fast 보장)
    ///   4. JSON 디코딩
    ///   5. 메인 스레드에서 응답 전달
    ///
    /// - 주의:
    ///   ErrorHandler가 커스텀된 경우 `transform()`에서 nil을 반환할 수 있으므로
    ///   아래에서 `response` / `data` 유효성 검사를 **한 번 더 수행**합니다.
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    internal func publish<T: Codable>(
        using client: NetworkClient,
        decoder: JSONDecoder,
        logging: Bool
    ) -> AnyPublisher<ApiResponse<T>, Error> {

        return self.publishData()
            .tryMap { dataResponse in

                self.log(dataResponse: dataResponse, logging: logging)

                return try self.processResponse(dataResponse, decoder: decoder, errorHandler: client.errorHandler)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
