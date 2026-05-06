//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation

@globalActor public actor APIActor {
    public static let shared = APIActor()
}

struct LogResponseError: Error {
    let request: URLRequest?
    let response: HTTPURLResponse?
    let underlyingError: any Error

    init(underlyingError: any Error, request: URLRequest?, response: HTTPURLResponse? = nil) {
        self.request = request
        self.response = response
        self.underlyingError = underlyingError
    }
}

struct ResponseData: Equatable {
    let request: URLRequest
    let response: HTTPURLResponse
    let json: NSString

    init(_ response: HTTPURLResponse, _ json: NSString, _ request: URLRequest) {
        self.request = request
        self.response = response
        self.json = json
    }
}

protocol APIClient {
    associatedtype Endpoint: EndpointProtocol
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func run<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error>
    func run<T: Decodable>(_ endpoint: Endpoint, logResponse: ((Result<ResponseData, LogResponseError>) -> Void)?) -> AnyPublisher<T, Error>
    func run<T: Decodable>(_ endpoint: Endpoint, receiveOn thread: DispatchQueue, logResponse: ((Result<ResponseData, LogResponseError>) -> Void)?) -> AnyPublisher<T, Error>
    func runForPlainText(_ endpoint: Endpoint) -> AnyPublisher<String, Error>
    func runForPlainText(_ endpoint: Endpoint, receiveOn thread: DispatchQueue) -> AnyPublisher<String, Error>
    func runRaw(_ endpoint: Endpoint) -> AnyPublisher<[String: Any], Error>
    func runRaw(_ endpoint: Endpoint, receiveOn thread: DispatchQueue) -> AnyPublisher<[String: Any], Error>
    func runRawAsync(_ endpoint: Endpoint) async throws -> [String: Any]
    func runRawAsync(_ endpoint: Endpoint, logResponse: ((Result<ResponseData, LogResponseError>) -> Void)?) async throws -> [String: Any]
}

extension ResponseData {
    var summaryNoRequest: NSString {
        let json = (json as String).isEmpty ? "(No Response Data)" : json
        return NSString(format: "Response: %d %@", response.statusCode, json)
    }

    var summaryNoRequestBody: NSString {
        let json = (json as String).isEmpty ? "(No Response Data)" : json
        return NSString(format: "%@\nResponse: %d %@", request.endpointSummary, response.statusCode, json)
    }

    func summary() -> NSString {
        let json = (json as String).isEmpty ? "(No Response Data)" : json
        return NSString(format: "%@\n\nResponse: %d %@", request.summary(), response.statusCode, json)
    }
}

extension LogResponseError {
    var summary: NSString {
        var result = NSString(string: "Underlying Error: \(underlyingError.localizedDescription)")
        if let request {
            result = NSString(format: "%@\n%@", result, request.endpointSummary)
        }
        if let response {
            result = NSString(format: "%@\nResponse: %d", result, response.statusCode)
        }
        return result
    }
}

extension Result<ResponseData, LogResponseError> {
    func print() {
        switch self {
        case .success(let log):
            Swift.print(log.summary())
        case .failure(let error):
            Swift.print(error.summary)
        }
    }
}
