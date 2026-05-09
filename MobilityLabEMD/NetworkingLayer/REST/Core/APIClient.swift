//
//  APIClient.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 7/30/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

@globalActor public actor APIActor {
    public static let shared = APIActor()
}

protocol APIClient {
    associatedtype Endpoint: EndpointProtocol
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}
