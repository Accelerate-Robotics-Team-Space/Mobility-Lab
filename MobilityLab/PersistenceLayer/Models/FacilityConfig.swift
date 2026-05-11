//
//  FacilityConfig.swift
//  MobilityLab BMM
//
//  Created by Vadym Riznychok on 4/15/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

struct FacilityConfig: Codable, Hashable {
    let complianceDegree: Int
    let turnProtocol: String
    let enableCompliance: Bool?
    let enableTurnProtocol: Bool?
}
