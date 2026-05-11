//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

final class AuthenticatedAPIClient<Endpoint: AuthenticatedEndpointProtocol>: URLSessionAPIClient<Endpoint> {
    private let keychain: Keychain = .shared

    override func buildRequest(from endpoint: Endpoint) throws -> URLRequest {
        var request = try super.buildRequest(from: endpoint)
        if endpoint.decorateWithStoredAuthToken, let authToken = keychain.accessToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
