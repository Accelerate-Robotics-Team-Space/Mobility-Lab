//
//  BMMInfoEndpoint.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 7/30/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

enum BMMInfoEndpoint: AuthenticatedEndpointProtocol {
    case getEMD(deviceId: String)
    case getEMDReconnect(deviceId: String)
    case getAnalytics(data: AnalyticsRequestData)

    var path: String {
        switch self {
        case .getEMD(let deviceId):
            return "api/v1/MobilityLabProvisioning/GetUnitMobilityMonitor/\(deviceId)"
        case .getEMDReconnect(let deviceId):
            return "api/v1/MobilityLabProvisioning/GetEMDReconnect/\(deviceId)"
        case .getAnalytics:
            return "api/v1/MobilityLabProvisioning/GetEMDAnalytics/LastDayFromTheDate"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getEMD, .getEMDReconnect, .getAnalytics:
            return .post
        }
    }

    var headers: [String: String]? {
        switch self {
        case .getAnalytics:
            return ["Content-Type": "application/json"]
        case .getEMD, .getEMDReconnect:
            return [
                "Connection": "keep-alive",
                "Keep-Alive": "30",
            ]
        }
    }

    var body: Data? {
        get throws {
            switch self {
            case .getEMD, .getEMDReconnect:
                return nil
            case .getAnalytics(let data):
                let bodyDict = [
                    "EMDId": data.ummId,
                    "FacilityId": data.facilityId,
                    "BmmId": data.bmmId,
                    "AnalyticsDate": data.date,
                    "SessionId": data.sessionId,
                ]
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .defaultEncoding
                return try encoder.encode(bodyDict)
            }
        }
    }
}
