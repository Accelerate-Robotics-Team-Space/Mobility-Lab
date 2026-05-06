//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_UMM

final class MockURLProtocol: URLProtocol {
    static var error: Error?
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var stopLoadingHandler: (() -> Void)?

    override static func canInit(with request: URLRequest) -> Bool { true }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let error = MockURLProtocol.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        guard let requestHandler = MockURLProtocol.requestHandler else {
            assertionFailure("Received unexpected request with no handler set")
            return
        }

        do {
            let (response, data) = try requestHandler(request) // this `request` will not contain `httpBody` data
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
