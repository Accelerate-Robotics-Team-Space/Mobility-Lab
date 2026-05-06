//
//  HospitalUnitInfo.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
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
    
    // MARK: - Static
    static let dev = HospitalUnitInfo()
    static let previewUnits = [HospitalUnitInfo(),
                               HospitalUnitInfo(),
                               HospitalUnitInfo(), ]

    static func getAll() -> [Self] {
        do {
            let info: [Self]? = try DataStore.shared.writer?.read { store in
                let request = HospitalUnit.including(all: HospitalUnit.rooms)
                return try HospitalUnitInfo.fetchAll(store, request)
            }
            
            return info ?? []
        } catch {
            logger.error(error.localizedDescription)
            return []
        }
    }
	
	static func getUnitInfo(forId id: String) -> HospitalUnitInfo? {
		let units = getAll()
		var lastRequestedUnit: HospitalUnitInfo?
		for unit in units where unit.id == id {
            lastRequestedUnit = unit
		}
		return lastRequestedUnit
	}
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
