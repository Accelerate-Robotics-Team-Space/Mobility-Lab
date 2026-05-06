//
//  PublishablePatient.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 12/28/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

struct PublishablePatient: Serializable {
    static let dev = PublishablePatient()

    let id: Int
    let sex: ALTSex
    let weightInLbs: Int
    let heightInInches: Int
    let props: String
    let hasPacemaker: Bool
    let hasSternumSkinBroken: Bool
    let turnProtocol: String
    let complianceDegree: Int

    // MARK: - Init
    private init() {
        self.id = 0
        self.sex = .noAnswer
        self.weightInLbs = 0
        self.heightInInches = 0
        self.props = ""
        self.hasPacemaker = false
        self.hasSternumSkinBroken = false
        self.turnProtocol = "Q2"
        self.complianceDegree = 20
    }

    func toPatientInfo() -> PatientInfo {
        return PatientInfo(id: id,
                           sexAtMeasurement: sex.rawValue,
                           weightInPounds: weightInLbs,
                           heightInInches: heightInInches,
                           hasPacemaker: hasPacemaker,
                           hasSternumSkinBroken: hasSternumSkinBroken,
                           props: props,
                           complianceDegree: complianceDegree,
                           turnProtocol: turnProtocol
        )
    }
}

// MARK: - Codable
extension PublishablePatient: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case sex = "SexAtMeasurement"
        case weightInLbs = "WeightInPounds"
        case heightInInches = "HeightInInches"
        case props = "Props"
        case hasPacemaker = "HasPacemaker"
        case hasSternumSkinBroken = "HasSternumSkinBroken"
        case turnProtocol = "TurnProtocol"
        case complianceDegree = "ComplianceDegree"
    }
}
