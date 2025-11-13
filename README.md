# ChaNetworkingSDK

Swift로 작성된 간결하고 강력한 네트워킹 SDK입니다. Alamofire를 기반으로 하며, Swift Concurrency(async/await)와 Combine을 모두 지원합니다.

## 주요 특징

- ✅ **Swift Concurrency 지원** - async/await 기반 API
- ✅ **Combine 지원** - Publisher 기반 API
- ✅ **타입 안전성** - 제네릭을 활용한 타입 안전한 응답 처리
- ✅ **유연한 에러 핸들링** - 커스텀 가능한 에러 처리 전략
- ✅ **풍부한 응답 정보** - 디코딩된 모델, Raw Data, HTTP Response 모두 제공
- ✅ **로깅 지원** - 디버깅을 위한 요청/응답 로깅 기능

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
    case noData                                  // 데이터 없음
    case decodingFailed(Error)                  // 디코딩 실패
    case serverError(statusCode: Int, message: String?) // 서버 에러
    case underlying(Error)                       // 기타 에러
}
```

## 기여

버그 리포트, 기능 제안, Pull Request를 환영합니다!

Issues: https://github.com/ninestar9552/ChaNetworkingSDK/issues

## 의존성

- [Alamofire](https://github.com/Alamofire/Alamofire) 5.10.2+

---

Made with by [ninestar9552](https://github.com/ninestar9552)
