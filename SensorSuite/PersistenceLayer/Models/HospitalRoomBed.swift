//
//  HospitalRoomBed.swift
//  SensorSuite
//
//  Created by Josh Franco on 10/12/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB

struct HospitalRoomBed: Codable, DataStorable, Serializable, Hashable {
    static let dev = HospitalRoomBed()
    static let previewRoomBeds = [
        HospitalRoomBed(),
        HospitalRoomBed(),
        HospitalRoomBed(),
    ]

    let id: String
    let facilityUnitId: String
    let roomBedNumber: String?
    let status: String?
    let lastModified: Date
    let lastModifiedBy: String?
    let serverLastModified: Date
}

extension HospitalRoomBed {
    static let unit = belongsTo(HospitalUnit.self)
    
    // MARK: - Init
    private init() {
        self.id = "preview_\(UUID().uuidString)"
        self.facilityUnitId = "FAKE_\(UUID().uuid)"
        self.roomBedNumber = "Fake Room \(Int.random(in: 0...1000))"
        self.status = nil
        self.lastModified = Date.distantPast
        self.lastModifiedBy = nil
        self.serverLastModified = Date.distantPast
    }
}

extension HospitalRoomBed: Equatable {
	static func == (_ lhs: HospitalRoomBed, _ rhs: HospitalRoomBed) -> Bool {
		return lhs.id == rhs.id
	}
}

extension HospitalRoomBed: Comparable {
	static func < (lhs: HospitalRoomBed, rhs: HospitalRoomBed) -> Bool {
		guard let lhsRoomBed = lhs.roomBedNumber, let rhsRoomBed = rhs.roomBedNumber else { return false }
		return lhsRoomBed < rhsRoomBed
	}
}
