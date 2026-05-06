//
//  RequestConstructible.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation

protocol RequestConstructible {
    var urlPathComponenet: String { get }
    var method: HTTPMethod { get }
    var body: Data? { get }
    var headers: [String: String]? { get }
    
    func specialityError(with code: Int) -> Error
}

// MARK: - Private Struct
private struct Response<T> {
    let value: T
    let response: URLResponse
}

// MARK: - Public
extension RequestConstructible {
    func specialityError(with code: Int) -> Error {
        switch code {
        case 500:
            return NetworkingErr.Rest.tempServerError
        default:
            return NetworkingErr.Rest.badStatusCode(code: code)
        }
    }
    
    // MARK: Runs
    func run<T: Decodable>(using decoder: JSONDecoder? = nil, onThread: DispatchQueue = .main) -> AnyPublisher<T, Error> {
        guard let baseUrl = URL(string: NetworkingConstants.baseUrlStr) else {
            return Fail(outputType: T.self, failure: NetworkingErr.Rest.badBaseUrl).eraseToAnyPublisher()
        }
        
        let request = constructRequest(using: baseUrl)
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> Response<T> in
                guard let urlResponse = result.response as? HTTPURLResponse else { throw NetworkingErr.Rest.badResponse }
                
                switch urlResponse.statusCode {
                case 200:
                    do {
                        let value = try (decoder ?? defaultDecoder).decode(T.self, from: result.data)
                        return Response(value: value, response: result.response)
                    } catch {
                        throw error
                    }
                case 400...500:
                    throw self.specialityError(with: urlResponse.statusCode)
                default:
                    throw NetworkingErr.Rest.badStatusCode(code: urlResponse.statusCode)
                }
            }
            .receive(on: onThread) // Deliver values on the specified thread (defaults to main)
            .map(\.value)
            .eraseToAnyPublisher()
    }
    
    func runForPlainText(onThread: DispatchQueue = .main) -> AnyPublisher<String, Error> {
        guard let baseUrl = URL(string: NetworkingConstants.baseUrlStr) else {
            return Fail(outputType: String.self, failure: NetworkingErr.Rest.badBaseUrl).eraseToAnyPublisher()
        }
        
        let request = constructRequest(using: baseUrl)
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> Response<String> in
                guard let urlResponse = result.response as? HTTPURLResponse else { throw NetworkingErr.Rest.badResponse }
                
                switch urlResponse.statusCode {
                case 200:
                    return Response(value: String(decoding: result.data, as: UTF8.self), response: result.response)
                case 400...500:
                    throw self.specialityError(with: urlResponse.statusCode)
                default:
                    throw NetworkingErr.Rest.badStatusCode(code: urlResponse.statusCode)
                }
            }
            .receive(on: onThread) // Deliver values on the specified thread (defaults to main)
            .map(\.value)
            .eraseToAnyPublisher()
    }
    
    func runRaw(onThread: DispatchQueue = .main) -> AnyPublisher<[String: Any], Error> {
        guard let baseUrl = URL(string: NetworkingConstants.baseUrlStr) else {
            return Fail(outputType: [String: Any].self, failure: NetworkingErr.Rest.badBaseUrl).eraseToAnyPublisher()
        }
        
        let request = constructRequest(using: baseUrl)
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> Response<[String: Any]> in
                let value = try JSONSerialization.jsonObject(with: result.data, options: []) as? [String: Any]
                return Response(value: value ?? [:], response: result.response)
            }
            .receive(on: onThread)
            .map(\.value)
            .eraseToAnyPublisher()
    }
}

// MARK: - Private
private extension RequestConstructible {
    var defaultDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
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
            
            throw NetworkingErr.Rest.badDateFormat
        }
        
        return decoder
    }
    
    func constructRequest(using baseUrl: URL) -> URLRequest {
        var request = URLRequest(url: baseUrl.appendingPathComponent(self.urlPathComponenet))
        
        // Set HTTP Method
        request.httpMethod = method.rawValue
        
        // Add Body if there is any
        request.httpBody = body
        
        // Set the headers
        headers?.forEach({ request.addValue($0.value, forHTTPHeaderField: $0.key) })
        
//        logger.debug(request.curl)
        return request
    }
}
