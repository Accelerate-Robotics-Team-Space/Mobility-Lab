//
//  EndpointProtocol.swift
//  SensorSuite UMM
//
//  Created by Vadym Riznychok on 7/30/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

protocol EndpointProtocol {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParameters: [String: String]? { get }
    var version: String? { get }
    var body: Data? { get throws }
}

extension EndpointProtocol {
    var baseURL: String {
        NetworkingConstants.baseUrlStr
    }

    var queryParameters: [String: String]? {
        nil
    }

    var version: String? {
        nil
    }
}
