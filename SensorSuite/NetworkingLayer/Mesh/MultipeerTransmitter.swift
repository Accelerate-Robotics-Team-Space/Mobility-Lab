//
//  MultipeerTransmitter.swift
//  SensorSuite
//
//  Created by Josh Franco on 4/12/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import Foundation

struct MultipeerTransmitter: Codable, Serializable {
    let topic: String
    let data: Data
    let isRetained: Bool
    let qosLvl: MQTTQosLevel
}
