//
//  DataFeedTopics.swift
//  SensorSuite
//
//  Created by Josh Franco on 3/12/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import Foundation

enum DataFeedTopics {
    case patientLocation(facilityID: String?, baseStationGuid: String?)
    case patientPosition(facilityID: String?, baseStationGuid: String?)
    case patientInfo(facilityID: String?, baseStationGuid: String?)

    case dataObservation(facilityID: String?, baseStationGuid: String?, wearableGuuid: UUID)
    case sessionObservation(facilityID: String?, baseStationGuid: String?, wearableGuuid: UUID)
    case trainingData(facilityID: String?, baseStationGuid: String?, wearableGuuid: UUID)
    case wearableLocation(facilityID: String?, baseStationGuid: String?, wearableGuuid: UUID)

    case appVersion(facilityID: String?, baseStationGuid: String?)
    case batteryLvl(facilityID: String?, baseStationGuid: String?)

    case wearableVersion(facilityID: String?, baseStationGuid: String?, wearableGuuid: UUID)
    case wearableBatteryLvl(facilityID: String?, baseStationGuid: String?, wearableGuuid: UUID)

    case endSession(facilityID: String?, baseStationGuid: String?)
}

// MARK: - Identifiable
extension DataFeedTopics: Identifiable {
    var id: Int {
        switch self {
        case .patientLocation(let facilityID, _), .patientPosition(let facilityID, _),
             .patientInfo(let facilityID, _), .appVersion(let facilityID, _), .batteryLvl(let facilityID, _), .endSession(let facilityID, _):
            facilityID?.hashValue ?? 0
        case let .dataObservation(facilityID, _, wearableGuuid), let .sessionObservation(facilityID, _, wearableGuuid),
             let .trainingData(facilityID, _, wearableGuuid), let .wearableLocation(facilityID, _, wearableGuuid),
             let .wearableVersion(facilityID, _, wearableGuuid), let .wearableBatteryLvl(facilityID, _, wearableGuuid):
            facilityID?.hashValue ?? 0 + wearableGuuid.hashValue
        }
    }
}

// MARK: - TopicStructurable
extension DataFeedTopics: TopicStructurable {
    enum TopicResult: TopicPublishable {
        case patientLocation(locStr: HospitalRoomBed)
        case patientPosition(flag: PositionalFlags)
        case patientInfo(info: PublishablePatient)

        case sessionObservation(sessionInfo: PublishableActivityLog)

        case dataObservation(point: DataPoint) // unused, consider deleting
        case trainingData(point: DataPoint) // unused, consider deleting
        
        case appVersion(ver: String)
        case batteryLvl(lvl: String)

        case wearableLocation(loc: WearableLocation)
        case wearableVersion(ver: String)
        case wearableBatteryLvl(lvl: String)

        case endSession(info: PublishablePatient) // unused, replaced with REST endpoint, consider deleting

        var isRetained: Bool {
            switch self {
            case .patientLocation, .patientPosition,
                .patientInfo, .appVersion, .wearableVersion, .endSession:
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
            case .patientInfo(let info), .endSession(let info):
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
        case .endSession:
            return ("data", "patient/end")
        }
    }
    
    var structure: String {
        let (prefix, suffix) = structPrefixSuffix
        let body: String

        switch self {
        case let .patientLocation(facilityID, baseStationGuid), let .patientPosition(facilityID, baseStationGuid),
             let .patientInfo(facilityID, baseStationGuid), let .appVersion(facilityID, baseStationGuid),
             let .batteryLvl(facilityID, baseStationGuid), let .endSession(facilityID, baseStationGuid):
            let facilityId = (facilityID ?? "?").uppercased()
            let baseStationId = baseStationGuid ?? "Unknown"
            body = "\(facilityId)/\(baseStationId.uppercased())"
        case let .dataObservation(facilityID, baseStationGuid, wearableGuuid), let .sessionObservation(facilityID, baseStationGuid, wearableGuuid),
             let .trainingData(facilityID, baseStationGuid, wearableGuuid), let .wearableLocation(facilityID, baseStationGuid, wearableGuuid),
             let .wearableVersion(facilityID, baseStationGuid, wearableGuuid), let .wearableBatteryLvl(facilityID, baseStationGuid, wearableGuuid):
            let facilityId = (facilityID ?? "?").uppercased()
            let baseStationId = baseStationGuid ?? "Unknown"
            body = "\(facilityId)/\(baseStationId.uppercased())/sensor/\(wearableGuuid.uuidString)"
        }
        
        return "\(prefix)/\(body)/\(suffix)"
    }
    
    func decodeResult(_ data: Data) -> TopicResult? {
        switch self {
        case .patientLocation:
            guard let locStr = HospitalRoomBed(serialize: data) else { return nil }
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
        case .endSession:
            guard let patient = PublishablePatient(serialize: data) else { return nil }
            return .endSession(info: patient)
        }
    }
}
