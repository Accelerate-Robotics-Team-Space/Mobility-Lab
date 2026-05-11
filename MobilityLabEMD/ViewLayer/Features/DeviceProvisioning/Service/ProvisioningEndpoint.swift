//
//  ProvisioningEndpoint.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 7/30/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

enum ProvisioningEndpoint: AuthenticatedEndpointProtocol {
    case registerEMD(deviceId: String)
    case getCertificateRevocationList(facilityId: String)
    case getUnitRooms(dateAfter: String?)
    case checkUnitRooms(dateAfter: String?)

    var path: String {
        switch self {
        case .registerEMD(let deviceId):
            return "api/v1/MobilityLabProvisioning/RegisterUnitMobilityMonitor/\(deviceId)"
        case .getCertificateRevocationList(let facilityId):
            return "api/v1/MobilityLabProvisioning/crl/\(facilityId)"
        case .getUnitRooms:
            return "api/v1/MobilityLabProvisioning/GetUnitRooms"
        case .checkUnitRooms:
            return "api/v1/MobilityLabProvisioning/CheckUnitRooms"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .registerEMD:
            return .post
        case .getCertificateRevocationList, .getUnitRooms, .checkUnitRooms:
            return .get
        }
    }

    var headers: [String: String]? {
        switch self {
        case .registerEMD:
            return ["Content-Type": "application/octet-stream"]
        case .getCertificateRevocationList:
            return nil
        case .checkUnitRooms, .getUnitRooms:
            return ["Content-Type": "application/json"]
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .getUnitRooms(let dateAfter), .checkUnitRooms(let dateAfter):
            guard let dateAfter = dateAfter else {
                return nil
            }
            return ["dateAfter": dateAfter]
        default:
            return nil
        }
    }

    var body: Data? { nil }
}
