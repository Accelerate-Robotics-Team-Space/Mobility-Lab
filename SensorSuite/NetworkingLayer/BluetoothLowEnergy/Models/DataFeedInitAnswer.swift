//
//  CouplingAnswer.swift
//  SensorSuite
//
//  Created by Josh Franco on 9/2/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

struct DataFeedInitAnswer: Serializable, Codable {
    let isCoupled: Bool
    let deviceName: String
    let wearableLocation: WearableLocation
    let facilityName: String
    
    init(isCoupled: Bool, deviceName: String, location: WearableLocation, facilityName: String) {
        self.isCoupled = isCoupled
        self.deviceName = deviceName
        self.wearableLocation = location
        self.facilityName = facilityName
    }
}
