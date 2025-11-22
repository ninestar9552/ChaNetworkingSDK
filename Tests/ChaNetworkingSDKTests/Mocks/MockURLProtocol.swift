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
final class HandlerStore {
    static private let queue = DispatchQueue(label: "handlerstore.queue")
    nonisolated(unsafe) static private var _store: [String: ((URLRequest) -> (HTTPURLResponse, Data))] = [:]

    static func set(_ key: String, handler: @escaping (URLRequest) -> (HTTPURLResponse, Data)) {
        queue.sync {
            _store[key] = handler
        }
    }

    static func get(_ key: String) -> ((URLRequest) -> (HTTPURLResponse, Data))? {
        queue.sync {
            _store[key]
        }
    }
}

final class MockURLProtocol: URLProtocol {
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let key = request.value(forHTTPHeaderField: "X-Test-ID") else {
            fatalError("Missing X-Test-ID")
        }
        
        guard let handler = HandlerStore.get(key) else {
            fatalError("Handler not set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
