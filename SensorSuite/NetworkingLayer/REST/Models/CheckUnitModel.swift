//
//  CheckUnitModel.swift
//  SensorSuiteBMM
//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//

import Foundation

struct CheckUnitModel: Codable, Hashable, Sendable {
    let doesNotHaveNewUnitsOrRooms: Bool
    let httpSuccess: Bool
    let exceptionCode: String?

    var unitsOrRoomsUpdated: Bool { !doesNotHaveNewUnitsOrRooms }
}

extension CheckUnitModel {
    enum CodingKeys: String, CodingKey {
        case doesNotHaveNewUnitsOrRooms = "data"
        case httpSuccess = "status"
        case exceptionCode
    }
}
