# ChaNetworkingSDK

Swift로 작성된 간결하고 강력한 네트워킹 SDK입니다. Alamofire를 기반으로 하며, Swift Concurrency(async/await)와 Combine을 모두 지원합니다.

## 주요 특징

- ✅ **Swift Concurrency 지원** - async/await 기반 API
- ✅ **Combine 지원** - Publisher 기반 API
- ✅ **타입 안전성** - 제네릭을 활용한 타입 안전한 응답 처리
- ✅ **유연한 에러 핸들링** - 커스텀 가능한 에러 처리 전략
- ✅ **풍부한 응답 정보** - 디코딩된 모델, Raw Data, HTTP Response 모두 제공
- ✅ **로깅 지원** - 디버깅을 위한 요청/응답 로깅 기능
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

## 사용법

### 기본 설정

```swift
import ChaNetworkingSDK
import Alamofire

// NetworkClient 인스턴스 생성
let client = NetworkClient(
    session: Session.default,
    encoding: JSONEncoding.default
)
```

### Swift Concurrency (async/await)

```swift
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

// GET 요청
do {
    let response: ApiResponse<User> = try await client.responseData(
        .get,
        "https://api.example.com/users/1"
    )

    print(response.value) // 디코딩된 User 모델
    print(response.httpResponse.statusCode) // 200
    print(response.data) // Raw Data
} catch let error as NetworkError {
    // 에러 처리
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

// POST 요청 with parameters
let parameters: [String: Any] = [
    "name": "Cha cha",
    "email": "cha@example.com"
]

let response: ApiResponse<User> = try await client.responseData(
    .post,
    "https://api.example.com/users",
    parameters: parameters,
    headers: ["Authorization": "Bearer YOUR_TOKEN"]
)
```

### Combine

```swift
import Combine

var cancellables = Set<AnyCancellable>()

// GET 요청
client.responseDataPublisher(.get, "https://api.example.com/users/1")
    .sink(
        receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("완료")
            case .failure(let error):
                print("에러: \(error)")
            }
        },
        receiveValue: { (response: ApiResponse<User>) in
            print("사용자: \(response.value.name)")
        }
    )
    .store(in: &cancellables)

// POST 요청 with parameters
let parameters: [String: Any] = [
    "name": "Cha cha",
    "email": "cha@example.com"
]

client.responseDataPublisher(
    .post,
    "https://api.example.com/users",
    parameters: parameters,
    headers: ["Authorization": "Bearer YOUR_TOKEN"]
)
.sink(
    receiveCompletion: { completion in
        // 완료 처리
    },
    receiveValue: { (response: ApiResponse<User>) in
        print("생성된 사용자 ID: \(response.value.id)")
    }
)
.store(in: &cancellables)
```

## Bearer Token 인증

`BearerTokenClient`는 Bearer Token 인증을 자동으로 처리하며, 401 에러 시 토큰을 자동으로 갱신하고 1번 재시도합니다.

### 기본 설정

```swift
import ChaNetworkingSDK
import Alamofire

// 1. Token Refresh 로직 정의
let tokenRefresher: TokenRefreshHandler = { currentRefreshToken, completion in
    // 여러분의 API 엔드포인트로 Refresh Token 요청
    AF.request(
        "https://api.example.com/auth/refresh",
        method: .post,
        parameters: ["refreshToken": currentRefreshToken],
        encoding: JSONEncoding.default
    )
    .responseDecodable(of: TokenResponse.self) { response in
        switch response.result {
        case .success(let tokenResponse):
            // 새 토큰을 completion으로 전달
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
    tokenStorage: KeychainTokenStorage(), // 기본값
    tokenRefresher: tokenRefresher,
    logging: true
)

// 3. 초기 로그인 후 토큰 저장
do {
    try client.tokenStorage.saveAccessToken("your_access_token")
    try client.tokenStorage.saveRefreshToken("your_refresh_token")
} catch {
    print("토큰 저장 실패: \(error)")
}
```

### 사용 예시

```swift
struct UserProfile: Codable {
    let id: Int
    let name: String
    let email: String
}

// async/await 방식
let response: ApiResponse<UserProfile> = try await client.request(
    .get,
    "/users/me" // baseURL과 자동으로 결합됨
)
print("사용자: \(response.value.name)")

// Combine 방식
client.requestPublisher(.get, "/users/me")
    .sink(
        receiveCompletion: { completion in
            // 완료 처리
        },
        receiveValue: { (response: ApiResponse<UserProfile>) in
            print("사용자: \(response.value.name)")
        }
    )
    .store(in: &cancellables)
```

### 자동 처리 기능

- ✅ 모든 요청에 자동으로 `Authorization: Bearer {token}` 헤더 추가
- ✅ 401 Unauthorized 응답 시 자동으로 토큰 갱신 시도
- ✅ 토큰 갱신 성공 시 실패한 요청 자동 재시도 (1번)
- ✅ 여러 요청이 동시에 401을 받아도 토큰 갱신은 1번만 실행
- ✅ 토큰 갱신 중인 다른 요청들은 대기 후 갱신된 토큰으로 재시도

### 고급 사용법: Adapter와 Retrier 분리

`BearerTokenClient`는 내부적으로 `BearerTokenAdapter`와 `BearerTokenRetrier`를 조합하여 사용합니다. 필요에 따라 이들을 독립적으로 사용할 수도 있습니다.

#### Bearer Token만 추가하고 재시도는 비활성화

```swift
import Alamofire

let tokenStorage = KeychainTokenStorage()
let adapter = BearerTokenAdapter(tokenStorage: tokenStorage)

let session = Session(
    configuration: .default,
    interceptor: adapter  // Adapter만 사용
)

let client = NetworkClient(session: session, logging: true)
```

#### 다른 Adapter와 함께 사용

```swift
// 여러 Adapter와 Retrier를 조합
let tokenAdapter = BearerTokenAdapter(tokenStorage: tokenStorage)
let customAdapter = MyCustomAdapter()

let tokenRetrier = BearerTokenRetrier(
    tokenStorage: tokenStorage,
    tokenRefresher: tokenRefresher
)

let interceptor = Interceptor(
    adapters: [tokenAdapter, customAdapter],
    retriers: [tokenRetrier]
)

let session = Session(
    configuration: .default,
    interceptor: interceptor
)

let client = NetworkClient(session: session)
```

### 토큰 저장소

#### KeychainTokenStorage (권장)

안전한 iOS Keychain을 사용한 토큰 저장소입니다:

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

### 커스텀 TokenStorage 구현

필요시 `TokenStorage` 프로토콜을 구현하여 커스텀 저장소를 만들 수 있습니다:

```swift
final class CustomTokenStorage: TokenStorage {
    func saveAccessToken(_ token: String) throws {
        // 커스텀 저장 로직
    }

    func saveRefreshToken(_ token: String) throws {
        // 커스텀 저장 로직
    }

    func getAccessToken() -> String? {
        // 커스텀 조회 로직
        return nil
    }

    func getRefreshToken() -> String? {
        // 커스텀 조회 로직
        return nil
    }

    func clearTokens() throws {
        // 커스텀 삭제 로직
    }
}
```

## Basic 인증

`BasicAuthClient`는 Username과 Password를 Base64 인코딩하여 자동으로 Authorization 헤더에 추가합니다.

### 기본 설정

```swift
import ChaNetworkingSDK

let client = BasicAuthClient(
    baseURL: "https://api.example.com",
    username: "your_username",
    password: "your_password",
    logging: true
)
```

### 사용 예시

```swift
// async/await 방식
let response: ApiResponse<UserProfile> = try await client.request(
    .get,
    "/users/me"
)

// Combine 방식
client.requestPublisher(.get, "/users/me")
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { (response: ApiResponse<UserProfile>) in
            print(response.value)
        }
    )
    .store(in: &cancellables)
```

### 자동 처리 기능

- ✅ 모든 요청에 자동으로 `Authorization: Basic {base64}` 헤더 추가
- ✅ Username과 Password는 Base64로 안전하게 인코딩

## 커스텀 에러 핸들링

기본 에러 핸들러를 커스터마이징할 수 있습니다:

```swift
struct CustomErrorHandler: NetworkErrorHandler {
    func transform(
        response: HTTPURLResponse?,
        data: Data?,
        error: AFError?
    ) -> Error? {
        // 401 에러 시 자동 로그아웃 처리 등
        if let response = response, response.statusCode == 401 {
            // 로그아웃 로직
            NotificationCenter.default.post(name: .userUnauthorized, object: nil)
        }

        if let error = error {
            return NetworkError.underlying(error)
        }

        guard let response = response else {
            return NetworkError.noResponse
        }

        guard let data = data else {
            return NetworkError.noData
        }

        if !(200..<300).contains(response.statusCode) {
            let message = String(data: data, encoding: .utf8)
            return NetworkError.serverError(statusCode: response.statusCode, message: message)
        }

        return nil
    }
}

// 커스텀 에러 핸들러로 클라이언트 생성
let client = NetworkClient(
    session: Session.default,
    errorHandler: CustomErrorHandler()
)
```

## 로깅

로깅은 `NetworkClient` 초기화 시 설정하며, 해당 클라이언트의 모든 요청에 적용됩니다:

```swift
// 로깅 활성화
let debugClient = NetworkClient(
    session: Session.default,
    logging: true
)

// 로깅 비활성화 (기본값)
let prodClient = NetworkClient(
    session: Session.default,
    logging: false
)
```

**권장 사항:**
- 개발/디버그 환경: `logging: true`
- 프로덕션 환경: `logging: false` (기본값)

## 프로젝트 구조

```
Sources/ChaNetworkingSDK/
├── Core/
│   └── NetworkClient.swift              # 메인 네트워크 클라이언트
├── Models/
│   ├── ApiResponse.swift                # 응답 래퍼
│   └── NetworkError.swift               # 에러 타입
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
│       ├── BearerTokenClient.swift      # Bearer Token 클라이언트
│       └── BasicAuthClient.swift        # Basic Auth 클라이언트
└── Extensions/
    ├── DataRequest+Response.swift       # 응답 처리 확장
    └── DataRequest+Logging.swift        # 로깅 확장
```

## ApiResponse 구조

```swift
public struct ApiResponse<Value> {
    public let value: Value              // 디코딩된 모델
    public let data: Data                // Raw Data
    public let httpResponse: HTTPURLResponse // HTTP 메타정보
}
```

이 구조를 통해 다음과 같은 유연성을 제공합니다:
- 디코딩된 모델에 직접 접근
- 필요시 Raw Data로 추가 파싱
- HTTP 상태 코드 및 헤더 정보 확인

## NetworkError 타입

```swift
public enum NetworkError: Error {
    case noResponse                              // 응답 없음
    case noData                                  // 데이터 없음 (커스텀 핸들러용)
    case decodingFailed(Error)                  // 디코딩 실패
    case serverError(statusCode: Int, message: String?) // 서버 에러
    case underlying(Error)                       // 기타 에러
}
```

## EmptyResponse

`204 No Content`처럼 response body가 없는 API 응답을 처리하기 위한 타입입니다.

### 사용 시점

- `204 No Content` 응답
- `DELETE` 요청 후 body 없는 응답
- `PUT/PATCH` 요청 후 body 없는 응답

### 사용 예시

```swift
// DELETE 요청
let response: ApiResponse<EmptyResponse> = try await client.delete(
    "https://api.example.com/users/1"
)
print(response.httpResponse.statusCode)  // 204

// PUT 요청 (응답 없음)
let _: ApiResponse<EmptyResponse> = try await client.put(
    "https://api.example.com/users/1/activate",
    parameters: nil
)
```

### 주의사항

| 상황 | 결과 |
|------|------|
| `EmptyResponse` + 빈 응답 | ✅ 정상 |
| `EmptyResponse` + body 있음 | ✅ 정상 (body 무시됨) |
| 다른 타입 + 빈 응답 | ❌ `NetworkError.noData` |

> **Note:** `EmptyResponse` 외의 타입으로 요청했는데 빈 응답이 오면 `NetworkError.noData` 에러가 발생합니다.

## 기여

버그 리포트, 기능 제안, Pull Request를 환영합니다!

Issues: https://github.com/ninestar9552/ChaNetworkingSDK/issues

## 의존성

- [Alamofire](https://github.com/Alamofire/Alamofire) 5.10.2+

---

Made with by [ninestar9552](https://github.com/ninestar9552)
