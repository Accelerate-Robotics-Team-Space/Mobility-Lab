//
//  MultipeerTransmitter.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 12/29/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

struct MultipeerTransmitter: Codable, Serializable {
    let topic: String
    let data: Data
    let isRetained: Bool
    let qosLvl: DeliveryAssurance
}
