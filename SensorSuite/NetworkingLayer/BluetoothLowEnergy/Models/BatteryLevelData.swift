//
//  BatteryLevelData.swift
//  SensorSuite
//
//  Created by Vadym Riznychok on 9/7/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import Foundation

struct BatteryLevelData: Serializable, Codable {
    let batteryLvl: UInt8
    let wearableId: String
}
