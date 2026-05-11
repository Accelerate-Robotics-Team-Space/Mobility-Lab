//
//  HospitalRoomBed.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB

struct HospitalRoomBed: Codable, DataStorable, Hashable {
    static let dev = HospitalRoomBed()
    static let previewRoomBeds = [HospitalRoomBed(),
                                  HospitalRoomBed(),
                                  HospitalRoomBed(), ]
    
    let id: String
    let facilityUnitId: String
    let roomBedNumber: String?
    let status: String?
    let lastModified: Date
    let lastModifiedBy: String?
    let serverLastModified: Date
    
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

	static func getRoomBed(forId id: String) -> HospitalRoomBed? {
		let room = try? DataStore.shared.reader.read { dataStore in
			return try HospitalRoomBed.fetchOne(
				dataStore,
				sql: """
  SELECT h.*
  FROM hospitalRoomBed h
  WHERE id = ?
  """,
				arguments: [id]
			)
		}
		return room
	}
}
