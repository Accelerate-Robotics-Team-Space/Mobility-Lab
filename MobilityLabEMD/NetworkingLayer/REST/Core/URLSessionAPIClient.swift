//
//  URLSessionAPIClient.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 7/30/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation

class URLSessionAPIClient<Endpoint: EndpointProtocol>: APIClient {
    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder = .init()

    init(
        urlSession: URLSession = .shared,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .defaultDecoding
    ) {
        self.urlSession = urlSession
        jsonDecoder.dateDecodingStrategy = dateDecodingStrategy
    }

    @APIActor
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try buildRequest(from: endpoint)

        let (data, response) = try await urlSession.data(for: request)
        try responseError(response: response, request: request)
        return try jsonDecoder.decode(T.self, from: data)
    }

    func buildRequest(from endpoint: Endpoint) throws -> URLRequest {
        guard var url = URL(string: endpoint.baseURL) else {
            print("Bad Base URL: \(endpoint.baseURL)")
            throw NetworkingError.REST.badBaseUrl
        }
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

    private func responseError(response: URLResponse, request: URLRequest) throws {
        guard let response = response as? HTTPURLResponse else {
            throw NetworkingError.REST.badResponse
        }
        guard 200...299 ~= response.statusCode else {
            throw NetworkingError.REST.badStatusCode(code: response.statusCode)
        }
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
