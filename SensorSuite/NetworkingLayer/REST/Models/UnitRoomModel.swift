//
//  UnitRoomModel.swift
//  SensorSuiteBMM
//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//

import Foundation

struct UnitRoomModel: Codable, Hashable {
    let facilityName: String
    let facilityId: UUID
    let units: [HospitalUnit]
    let roomBeds: [HospitalRoomBed]
}
