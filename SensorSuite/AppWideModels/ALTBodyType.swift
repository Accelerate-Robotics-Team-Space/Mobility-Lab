//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

enum ALTBodyType: String, Codable, CaseIterable {
    case round
    case muscular
    case slim
    
    var description: String {
        switch self {
        case .round:
            return "Ectomorph"
        case .muscular:
            return "Endomorph"
        case .slim:
            return "Mesomorph"
        }
    }
}
