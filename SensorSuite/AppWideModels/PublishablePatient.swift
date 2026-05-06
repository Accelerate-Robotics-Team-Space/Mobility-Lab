//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

struct PublishablePatient: Serializable {
    static let dev = PublishablePatient()

    let patientId: String
    let sex: ALTSex
    let weightInLbs: Int
    let heightInInches: Int
    let bmi: Double
    let hasPaceMaker: Bool
    let hasSternumSkinBroken: Bool
    let props: String
    let roomBedId: String
    let facilityUnitId: String
    let turnProtocol: String
    let complianceDegree: Int
    let sensorLocation: String

    // MARK: - Init
    init(
        patientId: String,
        sex: ALTSex,
        weight: Int,
        height: Int,
        bmi: Double,
        hasPaceMaker: Bool,
        hasSternumSkinBroken: Bool,
        props: String = "",
        roomBedId: String,
        facilityUnitId: String,
        turnProtocol: String,
        complianceDegree: Int,
        sensorLocation: String = ""
    ) {
        self.patientId = patientId
        self.sex = sex
        self.weightInLbs = weight
        self.heightInInches = height
        self.bmi = bmi
        self.hasPaceMaker = hasPaceMaker
        self.hasSternumSkinBroken = hasSternumSkinBroken
        self.props = props
        self.roomBedId = roomBedId
        self.facilityUnitId = facilityUnitId
        self.turnProtocol = turnProtocol
        self.complianceDegree = complianceDegree
        self.sensorLocation = sensorLocation
    }

    init(
        patient: ALTPatient,
        updatedProps: String?,
        facilityUnitID: String,
        turnProtocol: TurnProtocol,
        complianceDegree: ComplianceAngle,
        sensorLocation: String = ""
    ) {
        self.patientId = patient.id
        self.sex = patient.sex
        self.weightInLbs = patient.weightLbs
        self.heightInInches = patient.heightIn
        self.bmi = patient.bmi
        self.hasPaceMaker = patient.hasPaceMaker
        self.hasSternumSkinBroken = patient.hasSternumSkinBroken
        self.props = updatedProps ?? patient.props
        self.roomBedId = patient.hospitalRoomBedId
        self.facilityUnitId = facilityUnitID
        self.turnProtocol = turnProtocol.rawValue
        self.complianceDegree = complianceDegree.intValue
        self.sensorLocation = sensorLocation
    }
    private init() {
        self.patientId = ""
        self.sex = .noAnswer
        self.weightInLbs = 0
        self.heightInInches = 0
        self.bmi = 0.0
        self.hasPaceMaker = false
        self.hasSternumSkinBroken = false
        self.props = ""
        self.roomBedId = ""
        self.facilityUnitId = ""
        self.turnProtocol = "Q2"
        self.complianceDegree = 20
        self.sensorLocation = ""
    }
}

// MARK: - Codable
extension PublishablePatient: Codable {
    enum CodingKeys: String, CodingKey {
        case patientId
        case sex = "sexAtMeasurement"
        case weightInLbs = "weightInPounds"
        case heightInInches = "heightInInches"
        case bmi
        case hasPaceMaker
        case hasSternumSkinBroken
        case props
        case roomBedId
        case facilityUnitId
        case turnProtocol
        case complianceDegree
        case sensorLocation
    }
}
