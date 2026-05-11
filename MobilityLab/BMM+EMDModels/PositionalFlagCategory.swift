//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
import SwiftUI

enum PositionalFlagCategory: Int, CaseIterable, Hashable, Identifiable {
    case left
    case right
    case partialLeft
    case partialRight
    case supine
    case other

    init(_ string: String) {
        switch string {
        case "Supine": self = .supine
        case "Left Lateral": self = .left
        case "Right Lateral": self = .right
        case "Partial Left Lateral": self = .partialLeft
        case "Partial Right Lateral": self = .partialRight
        default: self = .other
        }
    }

    init?(abbreviation string: String) {
        switch string {
        case "S": self = .supine
        case "L": self = .left
        case "R": self = .right
        case "PL": self = .partialLeft
        case "PR": self = .partialRight
        default: return nil
        }
    }

    var id: Int {
        return rawValue
    }
    
    var imageStr: String {
        switch self {
        case .supine:
            R.image.positionSupine3.name
        case .left:
            R.image.positionLeftLateral3.name
        case .right:
            R.image.positionRightLateral3.name
        case .partialLeft:
            R.image.positionLeftLateral3.name
        case .partialRight:
            R.image.positionRightLateral3.name
        default:
            R.image.positionUnknown.name
        }
    }

    var imageStrPadding: String {
        switch self {
        case .supine:
            return "position-supine-1"
        case .left:
            return "position-left-lateral-1"
        case .right:
            return "position-right-lateral-1"
        case .partialLeft:
            return "position-left-lateral-1"
        case .partialRight:
            return "position-right-lateral-1"
        default:
            return "position-unknown"
        }
    }
    
    var flag: PositionalFlags {
        switch self {
        case .left:
            return .leftLateral
        case .right:
            return .rightLateral
        case .partialLeft:
            return .partialLeftLateral
        case .partialRight:
            return .partialRightLateral
        case .supine:
            return .supine
        case .other:
            return .unknown
        }
    }
	
    var description: String {
        switch self {
        case .left:
            return R.string.localizable.leftLateral()
        case .right:
            return R.string.localizable.rightLateral()
        case .partialLeft:
            return R.string.localizable.partialLeftLateral()
        case .partialRight:
            return R.string.localizable.partialRightLateral()
        case .supine:
            return R.string.localizable.supine()
        case .other:
            return R.string.localizable.other()
        }
    }

    var encoded: String {
        switch self {
        case .left:         "Left Lateral"
        case .right:        "Right Lateral"
        case .partialLeft:  "Partial Left Lateral"
        case .partialRight: "Partial Right Lateral"
        case .supine:       "Supine"
        case .other:        "Other"
        }
    }

    var abbreviation: String {
        switch self {
        case .left:
            return "L"
        case .right:
            return "R"
        case .partialLeft:
            return "PL"
        case .partialRight:
            return "PR"
        case .supine: // Double-check, assuming
            return "S"
        case .other:
            return "O"
        }
    }
    
    init(using flag: PositionalFlags) {
        switch flag {
        case .supine, .fowlers, .reverseTrendelenburg, .trendelenburg, [.fowlers, .reverseTrendelenburg]:
            self = .supine
        case .leftLateral:
            self = .left
        case .rightLateral:
            self = .right
        case .partialLeftLateral:
            self = .partialLeft
        case .partialRightLateral:
            self = .partialRight
        case .unknown:
            self = .other
        default:
            logger.warn("init PositionalFlagCategory from PositionalFlags failed. PositionalFlags: \(flag)")
            self = .other
        }
    }
    
    static func descriptionToPosition(description: String) -> PositionalFlagCategory {
        switch description {
        case R.string.localizable.supine():
            return PositionalFlagCategory.supine
        case R.string.localizable.leftLateral():
            return PositionalFlagCategory.left
        case R.string.localizable.rightLateral():
            return PositionalFlagCategory.right
        case R.string.localizable.partialLeftLateral():
            return PositionalFlagCategory.partialLeft
        case R.string.localizable.partialRightLateral():
            return PositionalFlagCategory.partialRight
        default:
            return PositionalFlagCategory.other
        }
    }

    var analyticsColor: Color {
        switch self {
        case .left:
            return .green3
        case .right:
            return .green3
        case .supine:
            return .green3
        case .partialLeft, .partialRight:
            return .yellow1
        default:
            return .gray
        }
    }

    func isCompliance(with targetPosition: PositionalFlagCategory) -> Bool {
        if targetPosition == .left {
            return [.left, .partialLeft].contains(self)
        } else if targetPosition == .right {
            return [.right, .partialRight].contains(self)
        } else {
            return self == targetPosition
        }
    }
}

extension PositionalFlagCategory: Codable {
    init(from decoder: any Decoder) throws {
        if let position = try? PositionalFlagCategory(rawValue: decoder.singleValueContainer().decode(RawValue.self)) {
            self = position
        } else {
            self = try PositionalFlagCategory(decoder.singleValueContainer().decode(String.self))
        }
    }
}
