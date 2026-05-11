//
//  HospitalUnit.swift
//  MobilityLab
//
//  Created by Josh Franco on 10/12/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB

struct HospitalUnit: DataStorable, Hashable {
    static let rooms = hasMany(HospitalRoomBed.self)
    static let dev = HospitalUnit()

    let id: String
    let facilityId: String
    let departmentId: String
    let name: String?
    let status: String?
    let lastModified: Date
    let lastModifiedBy: String?
    let serverLastModified: Date
}

extension HospitalUnit {
    // MARK: - init
    private init() {
        self.id = "72030CF0-A2B0-400F-9AB2-0FF1BAA6D4A3"
        self.facilityId = "BAA4114A-36A9-4594-AE15-E3166BD2D8F9"
        self.departmentId = "?"
        self.name = nil
        self.status = nil
        self.lastModified = Date.distantPast
        self.lastModifiedBy = nil
        self.serverLastModified = Date.distantPast
    }
    
    init(using info: HospitalUnitInfo) {
        self.id = info.id
        self.facilityId = info.facilityId
        self.departmentId = info.departmentId
        self.name = info.name
        self.status = info.status
        self.lastModified = info.lastModified
        self.lastModifiedBy = info.lastModifiedBy
        self.serverLastModified = info.serverLastModified
    }
}

extension HospitalUnit: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "facilityUnitId"
        case facilityId
        case departmentId
        case name
        case status
        case lastModified
        case lastModifiedBy
        case serverLastModified
    }
}
