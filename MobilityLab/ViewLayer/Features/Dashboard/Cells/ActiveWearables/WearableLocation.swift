//
//  WearableLocation.swift
//  MobilityLab
//
//  Created by Josh Franco on 12/28/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

enum WearableLocation: Int, Codable, CaseIterable, Serializable {
    case chest
    case back
    case leftArm
    case rightArm
    case leftLeg
    case rightLeg
    case unknown
    
    var description: String {
        switch self {
        case .chest:
            return R.string.localizable.chest()
        case .back:
            return R.string.localizable.back()
        case .leftArm:
            return R.string.localizable.leftArm()
        case .rightArm:
            return R.string.localizable.rightArm()
        case .leftLeg:
            return R.string.localizable.leftLeg()
        case .rightLeg:
            return R.string.localizable.rightLeg()
        case .unknown:
            return R.string.localizable.unknown()
        }
    }
}
