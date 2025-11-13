//
//  MockURLProtocol.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/12/25.
//

import Foundation

// MARK: - Mock URL Protocol
final class MockURLProtocol: URLProtocol {
    actor HandlerStore {
        static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.HandlerStore.requestHandler else {
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

final class MockURLProtocol2: URLProtocol {
    actor HandlerStore {
        static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol2.HandlerStore.requestHandler else {
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
