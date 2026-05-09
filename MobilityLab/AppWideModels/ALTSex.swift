//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
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
    
    var index: Int {
        switch self {
        case .male: return 0
        case .female: return 1
        case .other: return 2
        case .noAnswer: return 3
        }
    }
}
