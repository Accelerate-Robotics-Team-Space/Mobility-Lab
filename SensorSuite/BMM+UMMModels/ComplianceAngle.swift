//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

enum ComplianceAngle: String, Codable, Equatable, Sendable, CaseIterable {
    case angle20, angle25, angle30

    /// Partial-left: from partialAngle (20°/25°/30°) up to exactly 29.9995° (0.52359 rad)
    var partialLeftAngleRange: ClosedRange<Double> {
        (degree.radians)...(Degrees.thirtyMinus.radians)
    }

    /// Partial-right: from - 29.9995°° (−0.52359 rad) down to -partialAngle
    var partialRightAngleRange: ClosedRange<Double> {
        partialLeftAngleRange.negated()
    }

    var partialAngleDegree: Double { Double(degree.intValue) }

    var intValue: Int { degree.intValue }

    private var degree: Degrees {
        switch self {
        case .angle20:  .twenty
        case .angle25:  .twentyFive
        case .angle30:  .thirtyMinus
        }
    }

    var readable: String { "\(intValue)\u{00B0}" }

    init?(fromReadable: String) {
        switch fromReadable {
        case "20\u{00B0}":
            self = .angle20
        case "25\u{00B0}":
            self = .angle25
        case "30\u{00B0}":
            self = .angle30
        default:
            return nil
        }
    }

    init?(fromInt: Int) {
        switch fromInt {
        case 20:
            self = .angle20
        case 25:
            self = .angle25
        case 30:
            self = .angle30
        default:
            return nil
        }
    }
}
