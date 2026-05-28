//
//  BaseClientTests.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/17/25.
//

import Testing
import Foundation
import Alamofire
@testable import ChaNetworkingSDK

// MARK: - BaseClient Tests
final class BaseClientTests {

    // Helper: 테스트용 클라이언트 생성
    func createTestClient() -> (client: BaseClient, key: String) {
        let key = UUID().uuidString

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.httpAdditionalHeaders = ["X-Test-ID": key]

        let client = BaseClient(
            baseURL: "https://api.example.com",
            session: Session(configuration: configuration),
            logging: true
        )
        return (client, key)
    }

    @Test func testCustomSessionConfigurationIsUsed() async throws {
        let key = UUID().uuidString

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.httpAdditionalHeaders = [
            "X-Test-ID": key,
            "X-Custom-Session": "enabled"
        ]

        let client = BaseClient(
            baseURL: "https://api.example.com",
            session: Session(configuration: configuration)
        )

        var capturedCustomHeader: String?
        let mockJSON = #"{"id":1,"name":"Test User"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            capturedCustomHeader = request.value(forHTTPHeaderField: "X-Custom-Session")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        let _: ApiResponse<MockUser> = try await client.get("/users/me")

        #expect(capturedCustomHeader == "enabled")
    }

    // MARK: - Basic Request Test
    @Test func testBasicRequest() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        let mockJSON = #"{"id":1,"name":"Test User"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            // URL 경로 검증
            #expect(request.url?.absoluteString == "https://api.example.com/users/me")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: API 호출
        let response: ApiResponse<MockUser> = try await client.get("/users/me")

        // Then: 정상 응답 검증
        #expect(response.value.id == 1)
        #expect(response.value.name == "Test User")
        #expect(response.httpResponse.statusCode == 200)
    }

    // MARK: - No Authorization Header Test
    @Test func testNoAuthorizationHeader() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        var capturedAuthHeader: String?
        let mockJSON = #"{"id":1,"name":"Test User"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            // Authorization 헤더 캡처
            capturedAuthHeader = request.value(forHTTPHeaderField: "Authorization")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: API 호출
        let _: ApiResponse<MockUser> = try await client.get("/users/me")

        // Then: Authorization 헤더가 없어야 함
        #expect(capturedAuthHeader == nil)
    }

    // MARK: - Convenience Methods Test
    @Test func testConvenienceMethods() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // GET
        let getResponse: ApiResponse<MockUser> = try await client.get("/users/1")
        #expect(getResponse.httpResponse.statusCode == 200)

        // POST
        let postResponse: ApiResponse<MockUser> = try await client.post(
            "/users",
            parameters: ["name": "New User"]
        )
        #expect(postResponse.httpResponse.statusCode == 200)

        // PUT
        let putResponse: ApiResponse<MockUser> = try await client.put(
            "/users/1",
            parameters: ["name": "Updated"]
        )
        #expect(putResponse.httpResponse.statusCode == 200)

        // PATCH
        let patchResponse: ApiResponse<MockUser> = try await client.patch(
            "/users/1",
            parameters: ["name": "Patched"]
        )
        #expect(patchResponse.httpResponse.statusCode == 200)
    }

    @Test func testRawStringConvenience() async throws {
        let (client, key) = createTestClient()

        let mockText = "hello"
        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "text/plain"]
            )!
            return (response, mockText.data(using: .utf8)!)
        }

        let response: ApiResponse<String> = try await client.get("/hello")
        #expect(response.value == mockText)
    }

    @Test func testMultipartUpload() async throws {
        let (client, key) = createTestClient()

        var capturedContentType: String?
        let mockJSON = #"{"id":1,"name":"Uploaded"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            capturedContentType = request.value(forHTTPHeaderField: "Content-Type")
            #expect(request.httpMethod == "POST")
            #expect(request.url?.absoluteString == "https://api.example.com/upload")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        let response: ApiResponse<MockUser> = try await client.uploadMultipart(
            "/upload",
            fields: [MultipartField(name: "name", value: "sample")],
            files: [
                MultipartFile(
                    name: "file",
                    data: Data("file-data".utf8),
                    fileName: "sample.txt",
                    mimeType: "text/plain"
                )
            ]
        )

        #expect(response.value == MockUser(id: 1, name: "Uploaded"))
        #expect(capturedContentType?.contains("multipart/form-data") == true)
    }

    @Test func testMultipartUploadValueOnly() async throws {
        let (client, key) = createTestClient()

        let mockJSON = #"{"id":1,"name":"Uploaded"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.absoluteString == "https://api.example.com/upload")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        let user: MockUser = try await client.uploadMultipart(
            "/upload",
            fields: [MultipartField(name: "name", value: "sample")],
            files: [
                MultipartFile(
                    name: "file",
                    data: Data("file-data".utf8),
                    fileName: "sample.txt",
                    mimeType: "text/plain"
                )
            ]
        )

        #expect(user == MockUser(id: 1, name: "Uploaded"))
    }

    // MARK: - Empty Response Test
    @Test func testEmptyPayload() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())  // 빈 응답
        }

        // When: DELETE with EmptyPayload
        let response: ApiResponse<ChaNetworkingSDK.EmptyPayload> = try await client.delete("/users/1")

        // Then
        #expect(response.httpResponse.statusCode == 204)
        #expect(response.data.isEmpty)
    }

    // MARK: - Server Error Test
    @Test func testServerError() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        let mockJSON = #"{"error":"Not Found"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        do {
            let _: ApiResponse<MockUser> = try await client.get("/users/999")
            Issue.record("Expected error was not thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code, let message):
                #expect(code == 404)
                #expect(message == #"{"error":"Not Found"}"#)
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }

    // MARK: - URL Building Test
    @Test func testURLBuilding() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        var capturedURLs: [String] = []
        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            capturedURLs.append(request.url?.absoluteString ?? "")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // 상대 경로 (슬래시 있음)
        let _: ApiResponse<MockUser> = try await client.get("/users/1")
        #expect(capturedURLs.last == "https://api.example.com/users/1")

        // 상대 경로 (슬래시 없음)
        let _: ApiResponse<MockUser> = try await client.get("posts/1")
        #expect(capturedURLs.last == "https://api.example.com/posts/1")

        // 전체 URL (그대로 사용)
        let _: ApiResponse<MockUser> = try await client.get("https://other-api.com/data")
        #expect(capturedURLs.last == "https://other-api.com/data")
    }

    // MARK: - Value-Only Convenience Methods Test

    @Test func testValueOnlyGet() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        let mockJSON = #"{"id":1,"name":"Test User"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: T를 직접 반환 (ApiResponse 래핑 없이)
        let user: MockUser = try await client.get("/users/1")

        // Then: 디코딩된 값만 검증
        #expect(user.id == 1)
        #expect(user.name == "Test User")
    }

    @Test func testValueOnlyConvenienceMethods() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // GET
        let getUser: MockUser = try await client.get("/users/1")
        #expect(getUser.id == 1)

        // POST
        let postUser: MockUser = try await client.post(
            "/users",
            parameters: ["name": "New User"]
        )
        #expect(postUser.id == 1)

        // PUT
        let putUser: MockUser = try await client.put(
            "/users/1",
            parameters: ["name": "Updated"]
        )
        #expect(putUser.id == 1)

        // PATCH
        let patchUser: MockUser = try await client.patch(
            "/users/1",
            parameters: ["name": "Patched"]
        )
        #expect(patchUser.id == 1)
    }

    @Test func testParametersConvenienceMethodUsesCustomEncoding() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        var capturedBody: [String: Any]?
        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            let bodyData: Data?
            if let body = request.httpBody {
                bodyData = body
            } else if let bodyStream = request.httpBodyStream {
                bodyData = Data(reading: bodyStream)
            } else {
                bodyData = nil
            }
            if let bodyData {
                capturedBody = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: Parameters 기반 DELETE convenience 메서드에서 JSONEncoding 사용
        let response: ApiResponse<MockUser> = try await client.delete(
            "/search",
            parameters: ["keyword": "swift", "page": 4],
            encoding: JSONEncoding.default
        )

        // Then: custom encoding이 적용되어 body에 JSON이 포함되어야 함
        #expect(response.value.id == 1)
        #expect(capturedBody?["keyword"] as? String == "swift")
        #expect(capturedBody?["page"] as? Int == 4)
    }

    @Test func testValueOnlyParametersConvenienceMethodUsesCustomEncoding() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        var capturedBody: [String: Any]?
        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            let bodyData: Data?
            if let body = request.httpBody {
                bodyData = body
            } else if let bodyStream = request.httpBodyStream {
                bodyData = Data(reading: bodyStream)
            } else {
                bodyData = nil
            }
            if let bodyData {
                capturedBody = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: value-only DELETE convenience 메서드에서 JSONEncoding 사용
        let user: MockUser = try await client.delete(
            "/search",
            parameters: ["keyword": "swift", "page": 5],
            encoding: JSONEncoding.default
        )

        // Then: custom encoding이 적용되어 body에 JSON이 포함되어야 함
        #expect(user.id == 1)
        #expect(capturedBody?["keyword"] as? String == "swift")
        #expect(capturedBody?["page"] as? Int == 5)
    }

    @Test func testValueOnlyEncodableQuery() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        struct SearchQuery: Encodable {
            let keyword: String
            let page: Int
        }

        var capturedURL: String?
        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            capturedURL = request.url?.absoluteString
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: T 반환 + Encodable 쿼리
        let query = SearchQuery(keyword: "swift", page: 1)
        let user: MockUser = try await client.get("/search", query: query)

        // Then
        #expect(user.id == 1)
        #expect(capturedURL?.contains("keyword=swift") == true)
        #expect(capturedURL?.contains("page=1") == true)
    }

    @Test func testValueOnlyEncodableBody() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        struct CreateUserRequest: Encodable {
            let name: String
            let email: String
        }

        var capturedBody: [String: Any]?
        let mockJSON = #"{"id":1,"name":"Cha"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            if let bodyData = request.httpBodyStream {
                let data = Data(reading: bodyData)
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: T 반환 + Encodable body
        let body = CreateUserRequest(name: "Cha", email: "cha@example.com")
        let user: MockUser = try await client.post("/users", body: body)

        // Then
        #expect(user.id == 1)
        #expect(user.name == "Cha")
        #expect(capturedBody?["name"] as? String == "Cha")
        #expect(capturedBody?["email"] as? String == "cha@example.com")
    }

    @Test func testValueOnlyServerError() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        let mockJSON = #"{"error":"Not Found"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When & Then: T 반환 오버로드에서도 에러가 정상적으로 throw 되는지 검증
        do {
            let _: MockUser = try await client.get("/users/999")
            Issue.record("Expected error was not thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code, let message):
                #expect(code == 404)
                #expect(message == #"{"error":"Not Found"}"#)
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }

    // MARK: - Encodable Query Test
    @Test func testEncodableQuery() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        struct SearchQuery: Encodable {
            let keyword: String
            let page: Int
            let limit: Int
        }

        var capturedURL: String?
        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            capturedURL = request.url?.absoluteString
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: Encodable 쿼리로 GET 요청
        let query = SearchQuery(keyword: "test", page: 1, limit: 20)
        let _: ApiResponse<MockUser> = try await client.get("/search", query: query)

        // Then: URL에 쿼리 파라미터가 포함되어야 함
        #expect(capturedURL?.contains("keyword=test") == true)
        #expect(capturedURL?.contains("page=1") == true)
        #expect(capturedURL?.contains("limit=20") == true)
    }

    @Test func testEncodableRequestUsesCustomEncoder() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        struct SearchQuery: Encodable {
            let keyword: String
            let page: Int
        }

        var capturedURL: String?
        var capturedBody: Data?
        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            capturedURL = request.url?.absoluteString
            if let body = request.httpBody {
                capturedBody = body
            } else if let bodyStream = request.httpBodyStream {
                capturedBody = Data(reading: bodyStream)
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: POST 요청에 Encodable 파라미터를 쿼리스트링으로 인코딩
        let query = SearchQuery(keyword: "swift", page: 2)
        let _: ApiResponse<MockUser> = try await client.request(
            .post,
            "/search",
            parameters: query,
            encoder: URLEncodedFormParameterEncoder(destination: .queryString)
        )

        // Then: 커스텀 인코더가 적용되어 body 대신 URL 쿼리로 전송되어야 함
        #expect(capturedURL?.contains("keyword=swift") == true)
        #expect(capturedURL?.contains("page=2") == true)
        #expect(capturedBody == nil || capturedBody?.isEmpty == true)
    }

    @Test func testEncodableConvenienceMethodUsesCustomEncoder() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        struct SearchQuery: Encodable {
            let keyword: String
            let page: Int
        }

        var capturedURL: String?
        var capturedBody: Data?
        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            capturedURL = request.url?.absoluteString
            if let body = request.httpBody {
                capturedBody = body
            } else if let bodyStream = request.httpBodyStream {
                capturedBody = Data(reading: bodyStream)
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: POST convenience 메서드에서 Encodable 모델을 쿼리스트링으로 인코딩
        let query = SearchQuery(keyword: "swift", page: 3)
        let _: ApiResponse<MockUser> = try await client.post(
            "/search",
            body: query,
            encoder: URLEncodedFormParameterEncoder(destination: .queryString)
        )

        // Then: convenience 메서드에서도 커스텀 인코더가 적용되어야 함
        #expect(capturedURL?.contains("keyword=swift") == true)
        #expect(capturedURL?.contains("page=3") == true)
        #expect(capturedBody == nil || capturedBody?.isEmpty == true)
    }

    @Test func testValueOnlyEncodableConvenienceMethodUsesCustomEncoder() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        struct SearchQuery: Encodable {
            let keyword: String
            let page: Int
        }

        var capturedURL: String?
        var capturedBody: Data?
        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            capturedURL = request.url?.absoluteString
            if let body = request.httpBody {
                capturedBody = body
            } else if let bodyStream = request.httpBodyStream {
                capturedBody = Data(reading: bodyStream)
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: value-only POST convenience 메서드에서 Encodable 모델을 쿼리스트링으로 인코딩
        let query = SearchQuery(keyword: "swift", page: 6)
        let user: MockUser = try await client.post(
            "/search",
            body: query,
            encoder: URLEncodedFormParameterEncoder(destination: .queryString)
        )

        // Then: value-only convenience 메서드에서도 커스텀 인코더가 적용되어야 함
        #expect(user.id == 1)
        #expect(capturedURL?.contains("keyword=swift") == true)
        #expect(capturedURL?.contains("page=6") == true)
        #expect(capturedBody == nil || capturedBody?.isEmpty == true)
    }

    // MARK: - Encodable Body Test
    @Test func testEncodableBody() async throws {
        // Given: 클라이언트 생성
        let (client, key) = createTestClient()

        struct CreateUserRequest: Encodable {
            let name: String
            let email: String
        }

        var capturedBody: [String: Any]?
        let mockJSON = #"{"id":1,"name":"Test"}"#.data(using: .utf8)!
        MockURLProtocol.setHandler(key) { request in
            // Body 캡처
            if let bodyData = request.httpBodyStream {
                let data = Data(reading: bodyData)
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockJSON)
        }

        // When: Encodable body로 POST 요청
        let body = CreateUserRequest(name: "Cha", email: "cha@example.com")
        let _: ApiResponse<MockUser> = try await client.post("/users", body: body)

        // Then: Body에 JSON이 포함되어야 함
        #expect(capturedBody?["name"] as? String == "Cha")
        #expect(capturedBody?["email"] as? String == "cha@example.com")
    }
}

// MARK: - InputStream Helper
private extension Data {
    init(reading input: InputStream) {
        self.init()
        input.open()
        defer { input.close() }

        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            if read < 0 {
                break
            } else if read == 0 {
                break
            }
            self.append(buffer, count: read)
        }
    }
}
