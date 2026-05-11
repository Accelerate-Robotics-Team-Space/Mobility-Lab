//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

protocol EndpointProtocol: Sendable {
    func baseURL(host: String) -> String
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParameters: [String: String]? { get }
    var version: String? { get }
    var body: Data? { get throws }

    func validate(response: URLResponse) throws(NetworkingError.REST)
}

extension EndpointProtocol {
    func baseURL(host: String) -> String {
        NetworkingConstants.baseUrlStr(host: host)
    }

    var queryParameters: [String: String]? {
        nil
    }

    var version: String? {
        nil
    }

    func validate(response: URLResponse) throws(NetworkingError.REST) {
        guard let response = response as? HTTPURLResponse else {
            throw NetworkingError.REST.badResponse
        }
        switch response.statusCode {
        case 200...299:
            break
        case 400:
            throw NetworkingError.REST.someError("Error code 400, Bad request")
        case 401:
            throw NetworkingError.REST.someError("Error code 401, Unauthorized")
        case 500:
            throw NetworkingError.REST.tempServerError
        default:
            throw NetworkingError.REST.badStatusCode(code: response.statusCode)
        }
    }
}
