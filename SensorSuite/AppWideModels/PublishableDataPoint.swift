//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

struct PublishableDataPoint: Serializable {
    let rollAttitude: Double
    let pitchAttitude: Double
}

// MARK: - Codable
extension PublishableDataPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case rollAttitude
        case pitchAttitude
    }
}
