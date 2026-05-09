//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
import MQTTNIO

enum MQTTQosLevel: Int, Codable {
    case atMostOnce = 0
    case atLeastOnce
    case exactlyOnce

    func toNIOQos() -> MQTTQoS {
        switch self {
        case .atMostOnce:
            return .atMostOnce
        case .atLeastOnce:
            return .atLeastOnce
        case .exactlyOnce:
            return .exactlyOnce
        }
    }
}
