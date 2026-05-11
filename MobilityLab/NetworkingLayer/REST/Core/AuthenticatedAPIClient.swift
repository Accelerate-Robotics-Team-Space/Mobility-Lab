//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

final class AuthenticatedAPIClient<Endpoint: AuthenticatedEndpointProtocol>: URLSessionAPIClient<Endpoint> {
    private let keychain: KeychainProtocol

    override init(urlSession: URLSession = .shared, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .defaultDecoding, container: Container = .shared) {
        self.keychain = container.keychain.resolve()
        super.init(urlSession: urlSession, dateDecodingStrategy: dateDecodingStrategy, container: container)
    }

    override func buildRequest(from endpoint: Endpoint) throws -> URLRequest {
        var request = try super.buildRequest(from: endpoint)
        if endpoint.decorateWithStoredAuthToken, let authToken = keychain.accessToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
