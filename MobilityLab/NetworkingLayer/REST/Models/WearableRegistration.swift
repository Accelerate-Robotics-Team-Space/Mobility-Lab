//
//  WearableRegistration.swift
//  MobilityLab
//
//  Created by Josh Franco on 10/20/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

struct WearableRegistration: Codable, Serializable {
    let baseStationId: String
    let wearableId: String
    let intermediateCertificate: String
    let certificate: String
}
