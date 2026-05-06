//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation

final class MockURLProtocol: URLProtocol {
    static let urlSession: URLSession = {
        URLSession(configuration: .mock)
    }()

    static var error: Error?
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var stopLoadingHandler: (() -> Void)?

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        if let error = MockURLProtocol.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        guard let handler = MockURLProtocol.requestHandler else {
            assertionFailure("Received unexpected request with no handler set")
            return
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

    override func stopLoading() {
        guard let handler = MockURLProtocol.stopLoadingHandler else { fatalError("Stop Loading Handler must be set") }
        handler()
    }
}

extension URLSessionConfiguration {
    static var mock: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return configuration
    }
}
