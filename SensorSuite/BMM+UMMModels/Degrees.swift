//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//

import Foundation

enum Degrees: Double, CaseIterable {
    /// 16°\
    /// (4⋅π/45) rad ≈ 0.2792526803 rad
    case sixteen = 16

    /// 20°\
    /// 0.34906 rad (π/9 ≈ 0.3490658504 rad)
    case twenty = 20

    /// 25°\
    /// 0.43633 rad (5⋅π/36 ≈ 0.436332313 rad)
    case twentyFive = 25

    /// 29.9995°\
    /// 0.52359 rad
    case thirtyMinus = 29.9995

    /// 30°\
    /// (π/6) rad ≈ 0.523599 rad
    case thirty = 30

    /// 45°\
    /// (π/4) rad ≈ 0.7853981634 rad
    case fortyFive = 45

    /// 46.954°\
    /// ~ 0.8195019 rad
    case fortySevenMinus = 46.954

    /// 180°\
    /// π rad
    case oneEighty = 180

    var degrees: Double { rawValue }

    var intValue: Int {
        Int(rawValue.rounded(rounding))
    }

    var radians: Double {
        switch self {
        case .twenty:       0.34906 // approximation used previously in code
        case .twentyFive:   0.43633 // approximation used previously in code
        case .thirtyMinus:  0.52359 // approximation used previously in code
        default:            (degrees * .pi) / 180
        }
    }

    var displayText: String {
        "\(intValue)\u{00B0}"
    }

    private var rounding: FloatingPointRoundingRule {
        switch self {
        case .sixteen, .twenty, .twentyFive, .thirty, .fortyFive, .oneEighty:
                .toNearestOrAwayFromZero
        case .thirtyMinus, .fortySevenMinus:
                .up
        }
    }
}
