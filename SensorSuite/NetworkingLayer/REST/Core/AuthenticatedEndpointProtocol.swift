//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

protocol AuthenticatedEndpointProtocol: EndpointProtocol {
    var decorateWithStoredAuthToken: Bool { get }
}

extension AuthenticatedEndpointProtocol {
    var decorateWithStoredAuthToken: Bool { true }
}
