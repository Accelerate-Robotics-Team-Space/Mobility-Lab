//
//  ALTSession.swift
//  SensorSuite
//
//  Created by Josh Franco on 3/24/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation

// Important: -  Always use the provided static methods to access the ALTSession
struct ALTSession: DataStorable, Equatable {
	static let dev = ALTSession()
	
	let id: String
	let patientId: String
	let turningProtocol: TurningProtocol
	let positionsToAvoid: UInt32
	var hasEnded: Bool
	
	// MARK: - Computed Variable
	var patient: ALTPatient?

	// MARK: - Init
	private init() {
		self.id = "DEV_SESSION_5966D575-2FC1-438B-9147-578001D0EB56"
		self.patientId = ALTPatient.devPatient.id
		self.turningProtocol = .dev
		self.positionsToAvoid = 0
		self.hasEnded = false
	}
	
	init(
        patientId: String,
        turningProtocol: TurningProtocol,
        positionsToAvoid: PositionalFlags,
        hasEnded: Bool = false,
        id: String? = nil
    ) {
		self.id = id ?? UUID().uuidString
		self.patientId = patientId
		self.turningProtocol = turningProtocol
		self.positionsToAvoid = positionsToAvoid.rawValue
		self.hasEnded = hasEnded
	}
}

// MARK: - Codable
extension ALTSession: Codable {
	enum CodingKeys: String, CodingKey {
		case id = "sessionId"
		case patientId
		case turningProtocol
		case positionsToAvoid
		case hasEnded
	}
}
