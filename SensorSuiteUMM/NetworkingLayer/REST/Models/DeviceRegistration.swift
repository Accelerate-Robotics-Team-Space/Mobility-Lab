//
//  DeviceRegistration.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

struct FacilityConfig: Codable {
    let complianceDegree: Int
    let turnProtocol: String
    let enableCompliance: Bool?
    let enableTurnProtocol: Bool?
}

struct DeviceRegistration: Codable {
    let unitMobilityMonitorId: String
    let intermediateCertificate: String
    let certificate: String
    let facilityName: String
    let units: [HospitalUnit]
    let roomBeds: [HospitalRoomBed]
    let bmMs: [BMMStruct]
}

struct BMMStruct: Codable {
    let id: String
    let deviceSerialNumber: String
    let facilityId: String
    let facilityUnitId: String?
    let roomBedId: String?
    let bmmLastSeen: BMMLastSeen?
}

extension BMMStruct: Equatable { }

struct BMMStatus: Codable {
    let startBMMState: String?
    let bmmMonitoringState: String?
    let bmmPauseReason: String?
    let isWrongPosition: Bool
    let actualPosition: String
    let actualPositionStarted: String
    let startingTargetPosition: String
    let startingTimeRemaining: Double
    let sessionStartTime: String
    let roomBed: String
    let facilityUnitName: String
    let patientInfo: PatientInfo?
    let bmmName: String
    let bmmId: String
    let status: String
    let turnAngle: Int
    let headOfBedAngle: Int
    let bmmBatteryLevel: Int
    let sensorBatteryLevel: Int
}

extension BMMStatus: Equatable { }

struct PatientInfo: Codable {
    let id: Int
    let sexAtMeasurement: String
    let weightInPounds: Int
    let heightInInches: Int
    let hasPacemaker: Bool
    let hasSternumSkinBroken: Bool
    let props: String?
    let complianceDegree: Int?
    let turnProtocol: String?

}

extension PatientInfo: Equatable { }

struct Props: Codable {
    let avoid: String
}

struct BMMLastSeen: Codable, Equatable {
    let facilityUnitId: String?
    let facilityUnitName: String?
    let roomBedId: String?
    var roomBedNumber: String
    let lastSeenTime: String?
    let patientId: String?
    let altPatientId: String?
    var sessionId: String?
    let turnProtocol: String
    let complianceDegree: Int

    var daysLastSeen: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        if let date = formatter.date(from: lastSeenTime ?? "") {
            let fromDate = Calendar.current.startOfDay(for: date)
            let toDate = Calendar.current.startOfDay(for: Date())
            let numberOfDays = Calendar.current.dateComponents([.day], from: fromDate, to: toDate)
            // Magic number 31 here because anything more than 1 month old is irrelevant
            return numberOfDays.day ?? 31
        }
        return 31
    }
}

extension BMMLastSeen {
    var patientIdentifier: String {
        if let patientIdentifier = altPatientId {
            return patientIdentifier
        } else if let patientIdentifier = patientId {
            return patientIdentifier
        } else {
            return "No ID"
        }
    }
}
