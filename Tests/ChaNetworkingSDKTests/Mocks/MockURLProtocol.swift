//
//  MockURLProtocol.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/12/25.
//

import Foundation
import ChaNetworkingSDK
import Alamofire

// MARK: - Mock URL Protocol
final class MockURLProtocol: URLProtocol {
    static private let queue = DispatchQueue(label: "mock.urlprotocol.queue")
    static nonisolated(unsafe) private var handlerStore: [String: ((URLRequest) -> (HTTPURLResponse, Data))] = [:]

    static func setHandler(_ key: String, handler: @escaping (URLRequest) -> (HTTPURLResponse, Data)) {
        queue.sync {
            handlerStore[key] = handler
        }
    }

    static private func getHandler(_ key: String) -> ((URLRequest) -> (HTTPURLResponse, Data))? {
        queue.sync {
            handlerStore[key]
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let key = request.value(forHTTPHeaderField: "X-Test-ID") else {
            fatalError("Missing X-Test-ID")
        }

        guard let handler = Self.getHandler(key) else {
            fatalError("Handler not set")
        }

        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
