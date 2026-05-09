//
//  ALTSex.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 12/28/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

enum ALTSex: String, Codable, CaseIterable {
    case male = "M"
    case female = "F"
    case other = "U"
    case noAnswer = "N"
    
    var description: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .noAnswer: return "Decline to Answer"
        }
    }
}
