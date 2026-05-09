//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

enum TurnProtocol: String, Codable, Equatable, CaseIterable {

    case Q2, Q3, Q4 // swiftlint:disable:this identifier_name

    private var hours: Double {
        switch self {
        case .Q2:   2
        case .Q3:   3
        case .Q4:   4
        }
    }

    var duration: TimeInterval {
        hours * .secondsPerHour
    }

    var hoursInt: Int {
        Int(hours)
    }
}
