//
//  WearablePatch.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 1/31/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

class WearablePatch {
    var appliedAt: Date
    var expiredAt: Date
    var currentLocation: WearableLocation
    
    // MARK: - Init
    init(currentLocation: WearableLocation) {
        appliedAt = Date()
        expiredAt = Calendar.current.date(byAdding: .day, value: 1, to: appliedAt)!
        self.currentLocation = currentLocation
    }
}
