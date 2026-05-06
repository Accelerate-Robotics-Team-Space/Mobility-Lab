//
//  DataFeedTopics.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 12/28/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

enum DataFeedTopics {
    case patientLocation(baseStationId: String)
    case patientPosition(baseStationId: String)
    case patientInfo(baseStationId: String)
    
    case dataObservation(baseStationId: String)
    case sessionObservation(baseStationId: String)
    case trainingData(baseStationId: String)
    case wearableLocation(baseStationId: String)
    
    case appVersion(baseStationId: String)
    case batteryLvl(baseStationId: String)
    
    case wearableVersion(baseStationId: String)
    case wearableBatteryLvl(baseStationId: String)
}

// MARK: - Identifiable
extension DataFeedTopics: Identifiable {
    var id: Int {
        switch self {
        case .patientLocation, .patientPosition,
             .patientInfo, .appVersion, .batteryLvl:
            return UserDefaults.standard.facilityId?.hashValue ?? 0
        case .dataObservation(let baseStationId), .sessionObservation(let baseStationId),
                .trainingData(let baseStationId), .wearableLocation(let baseStationId),
                .wearableVersion(let baseStationId), .wearableBatteryLvl(let baseStationId):
            return UserDefaults.standard.facilityId?.hashValue ?? 0 + baseStationId.hashValue
        }
    }
}

// MARK: - TopicStructurable
extension DataFeedTopics: TopicStructurable {
    enum TopicResult: TopicPublishable {
        case patientLocation(locStr: String)
        case patientPosition(flag: PositionalFlags)
        case patientInfo(info: PublishablePatient)
        
        case dataObservation(point: DataPoint)
        case sessionObservation(sessionInfo: PublishableActivityLog)
        case trainingData(point: DataPoint)
        case wearableLocation(loc: WearableLocation)
        
        case appVersion(ver: String)
        case batteryLvl(lvl: String)
        
        case wearableVersion(ver: String)
        case wearableBatteryLvl(lvl: String)
        
        var isRetained: Bool {
            switch self {
            case .patientLocation, .patientPosition,
                 .patientInfo, .appVersion, .wearableVersion:
                return true
            case .dataObservation, .sessionObservation, .trainingData,
                 .wearableLocation, .batteryLvl, .wearableBatteryLvl:
                return false
            }
        }
        
        func toData() -> Data {
            switch self {
            case .patientLocation(let locStr):
                return locStr.toData()
            case .patientPosition(let flag):
                return flag.asData
            case .patientInfo(let info):
                return info.toData()
            case .dataObservation(let point), .trainingData(let point):
                return point.toData()
            case .sessionObservation(let sessionInfo):
                return sessionInfo.toData()
            case .wearableLocation(let loc):
                return loc.toData()
            case .appVersion(let ver), .wearableVersion(let ver):
                return ver.toData()
            case .batteryLvl(let lvl), .wearableBatteryLvl(let lvl):
                return lvl.toData()
            }
        }
    }
    
    var structPrefixSuffix: (String, String) {
        switch self {
        case .patientLocation:
            return ("data", "location")
        case .patientPosition:
            return ("data", "position")
        case .patientInfo:
            return ("data", "patient")
        case .dataObservation:
            return ("data", "observation")
        case .sessionObservation:
            return ("data", "session_observation")
        case .trainingData:
            return ("data", "training_data")
        case  .wearableLocation:
            return ("data", "location")
        case .appVersion, .wearableVersion:
            return ("control", "version")
        case .batteryLvl, .wearableBatteryLvl:
            return ("control", "battery_level")
        }
    }
    
    var structure: String {
        let (prefix, suffix) = structPrefixSuffix
        let body: String
        
        switch self {
        case .patientLocation(let baseStationId), .patientPosition(let baseStationId),
             .patientInfo(let baseStationId), .appVersion(let baseStationId), .batteryLvl(let baseStationId):
            let facilityId = (UserDefaults.standard.facilityId ?? "?").uppercased()
            body = "\(facilityId)/\(baseStationId.uppercased())"
        case .dataObservation(let baseStationId), .sessionObservation(let baseStationId),
             .trainingData(let baseStationId), .wearableLocation(let baseStationId),
             .wearableVersion(let baseStationId), .wearableBatteryLvl(let baseStationId):
            let facilityId = (UserDefaults.standard.facilityId ?? "?").uppercased()
            body = "\(facilityId)/\(baseStationId.uppercased())/sensor/+"
        }
        
        return "\(prefix)/\(body)/\(suffix)"
    }
    
    func decodeResult(_ data: Data) -> TopicResult? {
        switch self {
        case .patientLocation:
            guard let locStr = String(serialize: data) else { return nil }
            return .patientLocation(locStr: locStr)
        case .patientPosition:
            let flag = PositionalFlags.fromData(data)
            return .patientPosition(flag: flag)
        case .patientInfo:
            guard let patient = PublishablePatient(serialize: data) else { return nil }
            return .patientInfo(info: patient)
        case .dataObservation:
            guard let point = DataPoint(serialize: data) else { return nil }
            return .dataObservation(point: point)
        case .sessionObservation:
            guard let sessionInfo = PublishableActivityLog(serialize: data) else { return nil }
            return .sessionObservation(sessionInfo: sessionInfo)
        case .trainingData:
            guard let point = DataPoint(serialize: data) else { return nil }
            return .trainingData(point: point)
        case .wearableLocation:
            guard let loc = WearableLocation(serialize: data) else { return nil }
            return .wearableLocation(loc: loc)
        case .appVersion:
            guard let versionStr = String(serialize: data) else { return nil }
            return .appVersion(ver: versionStr)
        case .batteryLvl:
            guard let lvlStr = String(serialize: data) else { return nil }
            return .batteryLvl(lvl: lvlStr)
        case .wearableVersion:
            guard let versionStr = String(serialize: data) else { return nil }
            return .wearableVersion(ver: versionStr)
        case .wearableBatteryLvl:
            guard let lvlStr = String(serialize: data) else { return nil }
            return .wearableBatteryLvl(lvl: lvlStr)
        }
    }
}
