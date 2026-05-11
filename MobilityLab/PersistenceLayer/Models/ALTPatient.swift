//
//  ALTPatient.swift
//  MobilityLab
//
//  Created by Josh Franco on 12/8/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation

struct ALTPatient: DataStorable, Hashable {
	static let devPatient = ALTPatient()
	
	let id: String
    let createdAt: Date
    var altPatientId: String = ""

	private(set) var hospitalRoomBedId: String
	var heightMeasurement: Requirement = .inches
	var weightMeasurement: Requirement = .pounds
	var heightIn: Int = 0
	var weightLbs: Int = 0
	var hasPaceMaker: Bool
	var hasSternumSkinBroken: Bool
    var sex: ALTSex = .noAnswer
	var bmi: Double = 0
    var sensorLocation: String = ""
	var positionToAvoid: [PositionalFlagCategory: Bool] = [
		.left: false,
		.supine: false,
		.right: false,
	]
    var isSyncedToDB: Bool?
	var props: String
	var isSynced: Bool?
	private(set) var roomBed: HospitalRoomBed?

    func publishable(turnProtocol: TurnProtocol, complianceAngle: ComplianceAngle) -> PublishablePatient {
        PublishablePatient(
            patientId: id,
            sex: sex,
            weight: weightLbs,
            height: heightIn,
            bmi: bmi,
            hasPaceMaker: hasPaceMaker,
            hasSternumSkinBroken: hasSternumSkinBroken,
            props: props,
            roomBedId: hospitalRoomBedId,
            facilityUnitId: roomBed?.facilityUnitId ?? "",
            turnProtocol: turnProtocol.rawValue,
            complianceDegree: complianceAngle.intValue,
            sensorLocation: ""
        )
	}
	
	// MARK: - Computed Variable
	var formattedHeight: String {
		return String(heightIn)
	}
	
	var formattedWeight: String {
		return String(weightLbs)
	}
	
	// MARK: - Init
    init(
        hospitalRoomBedId: String,
        heightIn: Int,
        weightLbs: Int,
        hasPaceMaker: Bool,
        hasSternumSkinBroken: Bool,
        sex: ALTSex,
        bmi: Double,
        props: String,
        id: String = UUID().uuidString,
        createdAt: Date = .now
    ) {
        self.id = id
        self.hospitalRoomBedId = hospitalRoomBedId
        self.heightIn = heightIn
        self.weightLbs = weightLbs
        self.hasPaceMaker = hasPaceMaker
        self.hasSternumSkinBroken = hasSternumSkinBroken
        self.sex = sex
        self.bmi = bmi
        self.props = props
        self.isSynced = false
        self.createdAt = createdAt
    }
	
	init() {
		self.id = "DEV_Patient_5966D575-2FC1-438B-9147-578001D0EB56"
		self.hospitalRoomBedId = "Random hospital id / check"
		self.heightIn = 0
		self.weightLbs = 0
		self.hasPaceMaker = false
		self.hasSternumSkinBroken = false
        self.sex = .noAnswer
		self.bmi = 0
		self.props = ""
		self.isSynced = true
        self.createdAt = .now
	}

	mutating func resetCache() {
		heightMeasurement = Requirement.inches
		weightMeasurement = Requirement.pounds
		heightIn = 0
		weightLbs = 0
        sex = ALTSex.noAnswer
		bmi = 0
		positionToAvoid = [
			.left: false,
			.supine: false,
			.right: false,
		]
	}

    func posToAvoidFromProps() -> [PositionalFlagCategory] {
        guard !props.isEmpty else { return [] }
        return props
            .replacingOccurrences(of: "{\"avoid\":\"", with: "")
            .replacingOccurrences(of: "\"}", with: "")
			.flatMap { char in
                return [char].compactMap { return PositionalFlagCategory(abbreviation: String($0)) }
			}
    }

    mutating func update(roomBed: HospitalRoomBed) {
        self.hospitalRoomBedId = roomBed.id
        self.roomBed = roomBed
    }
}

// MARK: - Codable
extension ALTPatient: Codable {
	enum CodingKeys: String, CodingKey {
		case id = "patientId"
        case altPatientId
		case hospitalRoomBedId
		case heightIn
		case weightLbs
		case hasPaceMaker
		case hasSternumSkinBroken
		case sex
		case bmi
		case props
		case createdAt
		case isSynced
        case sensorLocation
	}
}

// MARK: - Profile Update
extension ALTPatient {
    struct ProfileUpdate {
        let height: Int
        let weight: Int
        let hasPaceMaker: Bool
        let hasSternumSkinBroken: Bool
        let sex: ALTSex
        let bmi: Double
        let props: String
        let altPatientId: String
        let sensorLocation: String
    }

    mutating func update(with profileUpdate: ProfileUpdate) {
        self.heightIn = profileUpdate.height
        self.weightLbs = profileUpdate.weight
        self.hasPaceMaker = profileUpdate.hasPaceMaker
        self.hasSternumSkinBroken = profileUpdate.hasSternumSkinBroken
        self.sex = profileUpdate.sex
        self.bmi = profileUpdate.bmi
        self.props = profileUpdate.props
        self.altPatientId = profileUpdate.altPatientId
        self.sensorLocation = profileUpdate.sensorLocation
    }

    func updated(with profileUpdate: ProfileUpdate) -> ALTPatient {
        var copy = self
        copy.update(with: profileUpdate)
        return copy
    }
}
