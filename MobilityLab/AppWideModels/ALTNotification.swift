//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

enum ALTNotification: Identifiable {
    case noWearable
    
    var description: String {
        switch self {
        case .noWearable:
            return "No Wearable Connected"
        }
    }
    
    var id: Int {
        self.hashValue
    }
}
