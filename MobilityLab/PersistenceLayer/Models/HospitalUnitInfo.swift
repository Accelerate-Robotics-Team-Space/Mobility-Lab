//
//  HospitalUnitInfo.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/17/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB

struct HospitalUnitInfo: FetchableRecord, Identifiable {
    let id: String
    let facilityId: String
    let departmentId: String
    let name: String?
    let status: String?
    let lastModified: Date
    let lastModifiedBy: String?
    let serverLastModified: Date
    let roomBeds: [HospitalRoomBed]
    
    // MARK: - Init
    private init() {
        self.id = "PREIVEW_\(UUID().uuidString)"
        self.facilityId = "32AA7D3A-BBFC-41A9-9FF2-2B9A785D0191"
        self.departmentId = "?"
        self.name = "TesterTed-\(Int.random(in: 0...99))"
        self.status = nil
        self.lastModified = Date.distantPast
        self.lastModifiedBy = nil
        self.serverLastModified = Date.distantPast
        self.roomBeds = HospitalRoomBed.previewRoomBeds
    }

    init(
        id: String,
        facilityId: String,
        departmentId: String,
        name: String?,
        status: String?,
        lastModified: Date,
        lastModifiedBy: String?,
        serverLastModified: Date,
        roomBeds: [HospitalRoomBed]
    ) {
        self.id = id
        self.facilityId = facilityId
        self.departmentId = departmentId
        self.name = name
        self.status = status
        self.lastModified = lastModified
        self.lastModifiedBy = lastModifiedBy
        self.serverLastModified = serverLastModified
        self.roomBeds = roomBeds
    }

    // MARK: - Static
    static let dev = HospitalUnitInfo()
    static let previewUnits = [
        HospitalUnitInfo(),
        HospitalUnitInfo(),
        HospitalUnitInfo(),
    ]
}

// MARK: - Codable
extension HospitalUnitInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "facilityUnitId"
        case facilityId
        case departmentId
        case name
        case status
        case lastModified
        case lastModifiedBy
        case serverLastModified
        case roomBeds = "hospitalRoomBeds"
    }
}

extension HospitalUnitInfo: Equatable {
	static func == (_ lhs: HospitalUnitInfo, _ rhs: HospitalUnitInfo) -> Bool {
		return lhs.id == rhs.id
	}
}
