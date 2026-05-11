//
//  AlertLevel.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 8/7/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
import SwiftUI

enum AlertLevel: Int, Comparable {
    case none
    case green
    case action
    case warning
    case critical

    var borderColor: Color {
        switch self {
        case .green:
            return .green1
        case .action:
            return .aqua1
        case .warning:
            return .yellow1
        case .critical:
            return .red1
        case .none:
            return .charcoal1
        }
    }

    var primaryTextColor: Color {
        switch self {
        case .green:
            return .green1
        case .action:
            return .aqua1
        case .warning:
            return .yellow1
        case .critical:
            return .red1
        case .none:
            return .charcoal1
        }
    }

    static func < (lhs: AlertLevel, rhs: AlertLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
