# ChaNetworkingSDK

Swift로 작성된 간결하고 강력한 네트워킹 SDK입니다. Alamofire를 기반으로 하며, Swift Concurrency(async/await)와 Combine을 모두 지원합니다.

## 주요 특징

- ✅ **Swift Concurrency 지원** - async/await 기반 API
- ✅ **Combine 지원** - Publisher 기반 API
- ✅ **타입 안전성** - 제네릭을 활용한 타입 안전한 응답 처리
- ✅ **유연한 에러 핸들링** - 커스텀 가능한 에러 처리 전략
- ✅ **풍부한 응답 정보** - 디코딩된 모델, Raw Data, HTTP Response 모두 제공
- ✅ **로깅 지원** - 디버깅을 위한 요청/응답 로깅 기능
- ✅ **BaseClient** - baseURL 기반 간편한 API 호출
- ✅ **Bearer Token 인증** - 자동 토큰 추가 및 갱신, 401 에러 시 자동 재시도
- ✅ **Basic 인증** - Username/Password 기반 인증 지원
- ✅ **안전한 토큰 저장** - Keychain 기반 토큰 저장소 제공

## 요구사항

- iOS 15.0+
- macOS 12.0+
- watchOS 8.0+
- tvOS 15.0+
- Swift 5.5+

## 설치

### Swift Package Manager

`Package.swift` 파일에 다음을 추가하세요:

```swift
dependencies: [
    .package(url: "https://github.com/ninestar9552/ChaNetworkingSDK.git", from: "1.0.0")
]
```

또는 Xcode에서:
1. File > Add Package Dependencies...
2. `https://github.com/ninestar9552/ChaNetworkingSDK.git` 입력
3. 버전 선택 후 추가

## 클라이언트 종류

| 클라이언트 | 설명 | baseURL | 인증 |
|-----------|------|---------|------|
| `NetworkClient` | 기본 클라이언트 | ❌ | ❌ |
| `BaseClient` | baseURL 지원 클라이언트 | ✅ | ❌ |
| `BearerTokenClient` | Bearer Token 인증 | ✅ | Bearer Token |
| `BasicAuthClient` | Basic 인증 | ✅ | Basic Auth |

## 사용법

### NetworkClient (기본)

전체 URL을 직접 지정하여 요청합니다.

```swift
import ChaNetworkingSDK
import Alamofire

let client = NetworkClient(
    session: Session.default,
    logging: true
)

// GET 요청
let response: ApiResponse<User> = try await client.responseData(
    .get,
    "https://api.example.com/users/1"
)
print(response.value.name)
```

### BaseClient (권장)

baseURL을 설정하고 상대 경로로 요청합니다. 인증이 필요 없는 공개 API에 적합합니다.

```swift
let client = BaseClient(
    baseURL: "https://api.example.com",
    logging: true
)

// 상대 경로로 요청
let user: ApiResponse<User> = try await client.get("/users/1")
let posts: ApiResponse<[Post]> = try await client.get("/posts")

// POST 요청
let newUser: ApiResponse<User> = try await client.post(
    "/users",
    parameters: ["name": "Cha", "email": "cha@example.com"]
)

// DELETE 요청
let _: ApiResponse<EmptyResponse> = try await client.delete("/users/1")
```

### Combine 지원

모든 클라이언트는 Combine Publisher를 지원합니다.

```swift
import Combine

var cancellables = Set<AnyCancellable>()

client.getPublisher("/users/1")
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("에러: \(error)")
            }
        },
        receiveValue: { (response: ApiResponse<User>) in
            print("사용자: \(response.value.name)")
        }
    )
    .store(in: &cancellables)
```

### HTTP 메서드 편의 기능

`BaseClient`, `BearerTokenClient`, `BasicAuthClient`는 다음 편의 메서드를 제공합니다:

```swift
// async/await - Dictionary 파라미터
client.get("/path", parameters: ["key": "value"])
client.post("/path", parameters: ["name": "Cha"])
client.put("/path", parameters: [...])
client.patch("/path", parameters: [...])
client.delete("/path")

// async/await - Encodable 파라미터
client.get("/path", query: SearchQuery(...))     // URL 쿼리
client.post("/path", body: CreateRequest(...))   // JSON body
client.put("/path", body: UpdateRequest(...))
client.patch("/path", body: PatchRequest(...))
client.delete("/path", query: DeleteQuery(...))  // URL 쿼리
```

### Encodable 파라미터 사용

타입 안전한 요청을 위해 `Encodable` 타입을 직접 사용할 수 있습니다:

```swift
// 쿼리 파라미터 (GET, DELETE)
struct SearchQuery: Encodable {
    let keyword: String
    let page: Int
    let limit: Int
}

let query = SearchQuery(keyword: "swift", page: 1, limit: 20)
let results: ApiResponse<[Post]> = try await client.get("/posts", query: query)
// → /posts?keyword=swift&page=1&limit=20

// Request Body (POST, PUT, PATCH)
struct CreateUserRequest: Encodable {
    let name: String
    let email: String
}

let request = CreateUserRequest(name: "Cha", email: "cha@example.com")
let user: ApiResponse<User> = try await client.post("/users", body: request)
```

| 메서드 | Dictionary | Encodable |
|--------|------------|-----------|
| GET | `parameters:` | `query:` |
| POST | `parameters:` | `body:` |
| PUT | `parameters:` | `body:` |
| PATCH | `parameters:` | `body:` |
| DELETE | `parameters:` | `query:` |

> **Note:** Encodable 파라미터는 `Sendable` 프로토콜도 준수해야 합니다. 일반적인 `struct`는 자동으로 `Sendable`을 준수하므로 대부분의 경우 추가 작업이 필요 없습니다.

## Bearer Token 인증

`BearerTokenClient`는 Bearer Token 인증을 자동으로 처리하며, 401 에러 시 토큰을 자동으로 갱신하고 재시도합니다.

### 기본 설정

```swift
import ChaNetworkingSDK
import Alamofire

// 1. Token Refresh 로직 정의
let tokenRefresher: TokenRefreshHandler = { currentRefreshToken, completion in
    AF.request(
        "https://api.example.com/auth/refresh",
        method: .post,
        parameters: ["refreshToken": currentRefreshToken],
        encoding: JSONEncoding.default
    )
    .responseDecodable(of: TokenResponse.self) { response in
        switch response.result {
        case .success(let tokenResponse):
            completion(.success((
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken
            )))
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

// 2. BearerTokenClient 초기화
let client = BearerTokenClient(
    baseURL: "https://api.example.com",
    tokenStorage: KeychainTokenStorage(),
    tokenRefresher: tokenRefresher,
    logging: true
)

// 3. 초기 로그인 후 토큰 저장
try client.tokenStorage.saveAccessToken("your_access_token")
try client.tokenStorage.saveRefreshToken("your_refresh_token")
```

### 사용 예시

```swift
// 자동으로 Authorization: Bearer {token} 헤더 추가
let response: ApiResponse<UserProfile> = try await client.get("/users/me")
print("사용자: \(response.value.name)")
```

### 자동 처리 기능

- ✅ 모든 요청에 자동으로 `Authorization: Bearer {token}` 헤더 추가
- ✅ 401 Unauthorized 응답 시 자동으로 토큰 갱신 시도
- ✅ 토큰 갱신 성공 시 실패한 요청 자동 재시도 (1번)
- ✅ 여러 요청이 동시에 401을 받아도 토큰 갱신은 1번만 실행
- ✅ 토큰 갱신 중인 다른 요청들은 대기 후 갱신된 토큰으로 재시도

### 토큰 저장소

#### KeychainTokenStorage (권장)

```swift
let storage = KeychainTokenStorage(
    service: "com.chanetworking.sdk.auth" // 기본값
)

// 토큰 저장
try storage.saveAccessToken("access_token_value")
try storage.saveRefreshToken("refresh_token_value")

// 토큰 조회
let accessToken = storage.getAccessToken()
let refreshToken = storage.getRefreshToken()

// 토큰 삭제 (로그아웃)
try storage.clearTokens()
```

#### 커스텀 TokenStorage 구현

```swift
final class CustomTokenStorage: TokenStorage {
    func saveAccessToken(_ token: String) throws { /* 구현 */ }
    func saveRefreshToken(_ token: String) throws { /* 구현 */ }
    func getAccessToken() -> String? { /* 구현 */ }
    func getRefreshToken() -> String? { /* 구현 */ }
    func clearTokens() throws { /* 구현 */ }
}
```

## Basic 인증

`BasicAuthClient`는 Username과 Password를 Base64 인코딩하여 자동으로 Authorization 헤더에 추가합니다.

```swift
let client = BasicAuthClient(
    baseURL: "https://api.example.com",
    username: "your_username",
    password: "your_password",
    logging: true
)

// 자동으로 Authorization: Basic {base64} 헤더 추가
let response: ApiResponse<UserProfile> = try await client.get("/users/me")
```

## 에러 처리

### NetworkError 타입

```swift
public enum NetworkError: Error {
    case noResponse                              // 응답 없음
    case noData                                  // 데이터 없음 (커스텀 핸들러용)
    case decodingFailed(Error)                   // 디코딩 실패
    case serverError(statusCode: Int, message: String?) // 서버 에러
    case underlying(Error)                       // 기타 에러
}
```

### 에러 처리 예시

```swift
do {
    let response: ApiResponse<User> = try await client.get("/users/1")
    print(response.value)
} catch let error as NetworkError {
    switch error {
    case .noResponse:
        print("응답 없음")
    case .noData:
        print("데이터 없음")
    case .decodingFailed(let decodingError):
        print("디코딩 실패: \(decodingError)")
    case .serverError(let statusCode, let message):
        print("서버 에러 [\(statusCode)]: \(message ?? "")")
    case .underlying(let afError):
        print("네트워크 에러: \(afError)")
    }
}
```

### 커스텀 에러 핸들링

```swift
struct CustomErrorHandler: NetworkErrorHandler {
    func transform(
        response: HTTPURLResponse?,
        data: Data?,
        error: AFError?
    ) -> Error? {
        // 401 에러 시 자동 로그아웃 처리
        if let response = response, response.statusCode == 401 {
            NotificationCenter.default.post(name: .userUnauthorized, object: nil)
        }

        // 기본 처리
        if let error = error { return NetworkError.underlying(error) }
        guard let response = response else { return NetworkError.noResponse }

        if !(200..<300).contains(response.statusCode) {
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            return NetworkError.serverError(statusCode: response.statusCode, message: message)
        }

        return nil
    }
}

let client = BaseClient(
    baseURL: "https://api.example.com",
    errorHandler: CustomErrorHandler()
)
```

## EmptyResponse

`204 No Content`처럼 response body가 없는 API 응답을 처리하기 위한 타입입니다.

```swift
// DELETE 요청
let response: ApiResponse<EmptyResponse> = try await client.delete("/users/1")
print(response.httpResponse.statusCode)  // 204

// PUT 요청 (응답 없음)
let _: ApiResponse<EmptyResponse> = try await client.put("/users/1/activate")
```

### 주의사항

| 상황 | 결과 |
|------|------|
| `EmptyResponse` + 빈 응답 | ✅ 정상 |
| `EmptyResponse` + body 있음 | ✅ 정상 (body 무시됨) |
| 다른 타입 + 빈 응답 | ❌ `NetworkError.noData` |

> **Note:** `EmptyResponse` 외의 타입으로 요청했는데 빈 응답이 오면 `NetworkError.noData` 에러가 발생합니다.

## 로깅

```swift
// 로깅 활성화 (개발/디버그)
let debugClient = BaseClient(baseURL: "...", logging: true)

// 로깅 비활성화 (프로덕션, 기본값)
let prodClient = BaseClient(baseURL: "...", logging: false)
```

## ApiResponse 구조

```swift
public struct ApiResponse<Value> {
    public let value: Value              // 디코딩된 모델
    public let data: Data                // Raw Data
    public let httpResponse: HTTPURLResponse // HTTP 메타정보
}
```

## 프로젝트 구조

```
Sources/ChaNetworkingSDK/
├── Core/
│   └── NetworkClient.swift              # 메인 네트워크 클라이언트
├── Models/
│   ├── ApiResponse.swift                # 응답 래퍼
│   ├── NetworkError.swift               # 에러 타입
│   └── EmptyResponse.swift              # 빈 응답 모델
├── ErrorHandling/
│   ├── NetworkErrorHandler.swift        # 에러 핸들러 프로토콜
│   └── DefaultNetworkErrorHandler.swift # 기본 에러 핸들러
├── Auth/
│   ├── Storage/
│   │   ├── TokenStorage.swift           # 토큰 저장소 프로토콜
│   │   └── KeychainTokenStorage.swift   # Keychain 기반 저장소
│   ├── Models/
│   │   └── TokenPair.swift              # 토큰 페어 모델
│   ├── Providers/
│   │   ├── BearerTokenAdapter.swift     # Bearer Token 헤더 추가
│   │   ├── BearerTokenRetrier.swift     # 401 재시도 및 토큰 갱신
│   │   └── BasicAuthAdapter.swift       # Basic Auth 처리
│   └── Clients/
│       ├── EndpointClient.swift         # baseURL 기반 클라이언트 프로토콜
│       ├── BaseClient.swift             # 기본 클라이언트 (인증 없음)
│       ├── BearerTokenClient.swift      # Bearer Token 클라이언트
│       └── BasicAuthClient.swift        # Basic Auth 클라이언트
└── Extensions/
    ├── DataRequest+Response.swift       # 응답 처리 확장
    └── DataRequest+Logging.swift        # 로깅 확장
```

## 기여

버그 리포트, 기능 제안, Pull Request를 환영합니다!

Issues: https://github.com/ninestar9552/ChaNetworkingSDK/issues

## 의존성

- [Alamofire](https://github.com/Alamofire/Alamofire) 5.10.2+

---

Made with by [ninestar9552](https://github.com/ninestar9552)
