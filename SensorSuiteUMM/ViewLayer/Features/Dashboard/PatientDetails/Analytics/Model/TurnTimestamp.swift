//
//  TurnTimestamp.swift
//  SensorSuite UMM
//
//  Created by Vadym Riznychok on 9/23/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

struct TurnTimestamp: Codable, Hashable {
    let turnTime: Date
    let targetPosition: PositionalFlagCategory
}
