//
//  BMMInfoEndpoint.swift
//  SensorSuite UMM
//
//  Created by Vadym Riznychok on 7/30/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

enum BMMInfoEndpoint: AuthenticatedEndpointProtocol {
    case getUMM(deviceId: String)
    case getUMMReconnect(deviceId: String)
    case getAnalytics(data: AnalyticsRequestData)

    var path: String {
        switch self {
        case .getUMM(let deviceId):
            return "api/v1/SensorSuiteProvisioning/GetUnitMobilityMonitor/\(deviceId)"
        case .getUMMReconnect(let deviceId):
            return "api/v1/SensorSuiteProvisioning/GetUMMReconnect/\(deviceId)"
        case .getAnalytics:
            return "api/v1/SensorSuiteProvisioning/GetUMMAnalytics/LastDayFromTheDate"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getUMM, .getUMMReconnect, .getAnalytics:
            return .post
        }
    }

    var headers: [String: String]? {
        switch self {
        case .getAnalytics:
            return ["Content-Type": "application/json"]
        case .getUMM, .getUMMReconnect:
            return [
                "Connection": "keep-alive",
                "Keep-Alive": "30",
            ]
        }
    }

    var body: Data? {
        get throws {
            switch self {
            case .getUMM, .getUMMReconnect:
                return nil
            case .getAnalytics(let data):
                let bodyDict = [
                    "UMMId": data.ummId,
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
