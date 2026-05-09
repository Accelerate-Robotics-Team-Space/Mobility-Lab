//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM

enum MockAuthenticatedAPIEndpoint: AuthenticatedEndpointProtocol {
    static var validateHandler: ((URLResponse) throws(NetworkingError.REST) -> Void)?
    static var baseURLHandler: ((String) -> String)?
    static var methodHandler: (() -> HTTPMethod)?
    static var pathHandler: (() -> String)?
    static var headersHandler: (() -> [String: String]?)?
    static var queryParametersHandler: (() -> [String: String]?)?
    static var bodyHandler: (() -> Data?)?
    static var versionHandler: (() -> String?)?

    func baseURL(host: String) -> String {
        MockAuthenticatedAPIEndpoint.baseURLHandler?(host) ?? "https://\(host)/"
    }

    var method: HTTPMethod {
        MockAuthenticatedAPIEndpoint.methodHandler?() ?? .get
    }

    var path: String {
        MockAuthenticatedAPIEndpoint.pathHandler?() ?? "a/path/to/test"
    }

    var headers: [String: String]? {
        MockAuthenticatedAPIEndpoint.headersHandler?()
    }

    var queryParameters: [String: String]? {
        MockAuthenticatedAPIEndpoint.queryParametersHandler?()
    }

    var body: Data? {
        MockAuthenticatedAPIEndpoint.bodyHandler?()
    }

    var version: String? {
        MockAuthenticatedAPIEndpoint.versionHandler?()
    }

    func validate(response: URLResponse) throws(NetworkingError.REST) {
        try MockAuthenticatedAPIEndpoint.validateHandler?(response)
    }
}
