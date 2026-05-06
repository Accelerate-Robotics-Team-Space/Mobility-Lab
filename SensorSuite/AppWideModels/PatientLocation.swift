//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

struct PatientLocation {
    static let dev = PatientLocation()
    
    let unit: HospitalUnit
    let roomBed: HospitalRoomBed
    
    // MARK: - Init
    private init() {
        self.unit = HospitalUnit.dev
        self.roomBed = HospitalRoomBed.dev
    }
    
    init(info: HospitalUnitInfo, roomBed: HospitalRoomBed) {
        self.unit = HospitalUnit(using: info)
        self.roomBed = roomBed
    }
    
    init(unit: HospitalUnit, roomBed: HospitalRoomBed) {
        self.unit = unit
        self.roomBed = roomBed
    }
}

// MARK: - Hashable
extension PatientLocation: Hashable {
    static func == (lhs: PatientLocation, rhs: PatientLocation) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(unit.facilityId.hashValue)
    }
}
