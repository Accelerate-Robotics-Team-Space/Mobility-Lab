//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation

class URLSessionAPIClient<Endpoint: EndpointProtocol>: APIClient {
    let container: Container
    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder = .init()
    private let userDefaults: BMMUserDefaultsServiceProtocol

    init(
        urlSession: URLSession = .shared,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .defaultDecoding,
        container: Container = .shared
    ) {
        self.container = container
        self.urlSession = urlSession
        self.userDefaults = container.userDefaults.resolve()
        jsonDecoder.dateDecodingStrategy = dateDecodingStrategy
    }

    @APIActor
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try buildRequest(from: endpoint)

        let (data, response) = try await urlSession.data(for: request)
        try endpoint.validate(response: response)
        return try jsonDecoder.decode(T.self, from: data)
    }

    func run<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error> {
        run(endpoint, receiveOn: .main, logResponse: nil)
    }

    func run<T: Decodable>(_ endpoint: Endpoint, logResponse: ((Result<ResponseData, LogResponseError>) -> Void)?) -> AnyPublisher<T, Error> {
        run(endpoint, receiveOn: .main, logResponse: logResponse)
    }

    func run<T: Decodable>(_ endpoint: Endpoint, receiveOn thread: DispatchQueue, logResponse: ((Result<ResponseData, LogResponseError>) -> Void)?) -> AnyPublisher<T, Error> {
        let request: URLRequest
        do {
            request = try buildRequest(from: endpoint)
        } catch {
            logResponse?(.failure(.init(underlyingError: error, request: nil)))
            return Fail(outputType: T.self, failure: error).eraseToAnyPublisher()
        }

        return urlSession.dataTaskPublisher(for: request)
            .tryCatch { error -> AnyPublisher<URLSession.DataTaskPublisher.Output, any Error> in
                //                  typealias URLSession.DataTaskPublisher.Output = (data: Data, response: URLResponse)
                logResponse?(.failure(.init(underlyingError: error, request: request)))
                return Fail(error: error).eraseToAnyPublisher()
            }
            .tryMap { result -> T in
                do {
                    try endpoint.validate(response: result.response)
                    let decodedOutput = try self.jsonDecoder.decode(T.self, from: result.data)
                    if let logResponse, let httpResponse = result.response as? HTTPURLResponse {
                        let json = result.data.prettyJSON() ?? NSString(string: "INVALID DATA")
                        logResponse(.success(.init(httpResponse, json, request)))
                    }
                    return decodedOutput
                } catch {
                    logResponse?(.failure(.init(underlyingError: error, request: request, response: result.response as? HTTPURLResponse)))
                    throw error
                }
            }
            .receive(on: thread) // Deliver values on the specified thread (defaults to main)
            .eraseToAnyPublisher()
    }

    func runForPlainText(_ endpoint: Endpoint) -> AnyPublisher<String, Error> {
        runForPlainText(endpoint, receiveOn: .main)
    }

    func runForPlainText(_ endpoint: Endpoint, receiveOn thread: DispatchQueue) -> AnyPublisher<String, Error> {
        let request: URLRequest
        do {
            request = try buildRequest(from: endpoint)
        } catch {
            return Fail(
                outputType: String.self,
                failure: error
            ).eraseToAnyPublisher()
        }
        
        return urlSession.dataTaskPublisher(for: request)
            .tryMap { result -> String in
                try endpoint.validate(response: result.response)
                guard let string = String(data: result.data, encoding: .utf8) else {
                    throw NetworkingError.REST.badResponse
                }
                return string
            }
            .receive(on: thread)
            .eraseToAnyPublisher()
    }

    func runRaw(_ endpoint: Endpoint) -> AnyPublisher<[String: Any], Error> {
        runRaw(endpoint, receiveOn: .main)
    }

    func runRaw(_ endpoint: Endpoint, receiveOn thread: DispatchQueue) -> AnyPublisher<[String: Any], Error> {
        let request: URLRequest
        do {
            request = try buildRequest(from: endpoint)
        } catch {
            return Fail(
                outputType: [String: Any].self,
                failure: error
            ).eraseToAnyPublisher()
        }

        return urlSession.dataTaskPublisher(for: request)
            .tryMap { result -> [String: Any] in
                try endpoint.validate(response: result.response)
                guard let dictionary = try JSONSerialization.jsonObject(with: result.data, options: []) as? [String: Any] else {
                    throw NetworkingError.REST.badResponse
                }
                return dictionary
            }
            .receive(on: thread)
            .eraseToAnyPublisher()
    }

    func runRawAsync(_ endpoint: Endpoint) async throws -> [String: Any] {
        try await runRawAsync(endpoint, logResponse: nil)
    }

    func runRawAsync(_ endpoint: Endpoint, logResponse: ((Result<ResponseData, LogResponseError>) -> Void)?) async throws -> [String: Any] {
        // build request errors not sent to `logResponse` closure
        let request = try buildRequest(from: endpoint)

        let (data, response) = try await urlSession.data(for: request)

        do {
            try endpoint.validate(response: response)
            let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            if let logResponse, let httpResponse = response as? HTTPURLResponse {
                let json = data.prettyJSON() ?? NSString(string: "")
                logResponse(.success(ResponseData(httpResponse, json, request)))
            }
            return result ?? [:]
        } catch {
            if let logResponse {
                logResponse(.failure(LogResponseError(underlyingError: error, request: request, response: response as? HTTPURLResponse)))
            }
            throw error
        }
    }

    func buildRequest(from endpoint: Endpoint) throws -> URLRequest {
        guard var url = URL(string: endpoint.baseURL(host: userDefaults.host)) else { throw NetworkingError.REST.badBaseUrl }
        url = url.appending(path: endpoint.path)
        if let queryParameters = endpoint.queryParameters {
            let queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            url.append(queryItems: queryItems)
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        endpoint.headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        if let body = try endpoint.body {
            request.httpBody = body
        }
        return request
    }
}

public extension JSONDecoder.DateDecodingStrategy {
    static var defaultDecoding: JSONDecoder.DateDecodingStrategy {
        .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)

            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS"
            if let date = formatter.date(from: dateStr) {
                return date
            }

            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = formatter.date(from: dateStr) {
                return date
            }

            throw NetworkingError.REST.badDateFormat
        }
    }
}

public extension JSONEncoder.DateEncodingStrategy {
    static var defaultEncoding: JSONEncoder.DateEncodingStrategy {
        .custom({ date, encoder in
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS"

            let stringData = formatter.string(from: date)
            var container = encoder.singleValueContainer()
            try container.encode(stringData)
        })
    }
}
