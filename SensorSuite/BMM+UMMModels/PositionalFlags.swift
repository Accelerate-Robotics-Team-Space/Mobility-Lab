//
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

/// Defined positional flags.
///
/// - Note:
/// Some of these can be combined depending on the situation.  Such as Upright Standing & Upright Sitting.
/// In that case, the description will display both values delimited by a slash (/) character.
///
/// - Tag: PositionalFlags
struct PositionalFlags: OptionSet, Codable {
    let rawValue: UInt32
    
    // MARK: - Positions
    static let allFlags: [PositionalFlags] = [
        .supine, .leftLateral, .rightLateral,
        .fowlers, .reverseTrendelenburg, trendelenburg,
        .unknown,
    ]

    /// A position where the patient lies on his back with his chest facing up.
    static let supine = PositionalFlags(rawValue: 1 << 0)
    
    /// This position involves the patient lying on left side.
    /// Left lateral means the patient’s left side is touching the bed.
    static let leftLateral = PositionalFlags(rawValue: 1 << 2)

    /// This position involves the patient lying on partialy left side.
    /// Partial Left lateral means the patient’s left side is touching the bed but it's not enough to be in Left lateral.
    static let partialLeftLateral = PositionalFlags(rawValue: 1 << 3)
    
    /// This position involves the patient lying on right side.
    /// Right lateral means the patient’s right side is touching the bed.
    static let rightLateral = PositionalFlags(rawValue: 1 << 4)

    /// This position involves the patient lying on partialy right side.
    /// Partial Right lateral means the patient’s right side is touching the bed but it's not enough to be in Right lateral.
    static let partialRightLateral = PositionalFlags(rawValue: 1 << 5)
    
    /// A bed position where the head and trunk are raised.  A reclined sitting position.
    ///
    /// Resolves to `.supine` when sent to server
    static let fowlers = PositionalFlags(rawValue: 1 << 6)
    
    /// The patient is supine with the head of the bed elevated and the foot of
    /// the bed down.
    ///
    /// Resolves to `.supine` when sent to server
    static let reverseTrendelenburg = PositionalFlags(rawValue: 1 << 7)
    
    /// This position involves a supine patient and sharply lowering the head of the bed
    /// and raising the foot, creating an “upside down” effect.
    ///
    /// Resolves to `.supine` when sent to server
    static let trendelenburg = PositionalFlags(rawValue: 1 << 8)
    
    /// A person engaged in activity that registers as steps by the sensor.
    static let walking = PositionalFlags(rawValue: 1 << 11)
    
    static let unknown = PositionalFlags([])
    
    // MARK: - Computed Variables
    var imageStrPadding: String {
        switch self {
        case .supine, [.trendelenburg, .fowlers, .reverseTrendelenburg, .trendelenburg]:
            return "position-supine-1"
        case .leftLateral:
            return "position-left-lateral-1"
        case .rightLateral:
            return "position-right-lateral-1"
        case .partialLeftLateral:
            return "position-left-lateral-1"
        case .partialRightLateral:
            return "position-right-lateral-1"
        case .fowlers:
            return "position-fowlers"
        case .reverseTrendelenburg:
            return "position-reverse-trendelenburg"
        case [.fowlers, .reverseTrendelenburg]:
            return "position-combo-trendelenburg-fowlers"
        case .trendelenburg:
            return "position-trendelenburg"
        default:
            return "position-unknown"
        }
    }

    var imageStr: String {
        switch self {
        case .supine, [.trendelenburg, .fowlers, .reverseTrendelenburg, .trendelenburg]:
            return R.image.positionSupine3.name
        case .leftLateral:
            return R.image.positionLeftLateral3.name
        case .rightLateral:
            return R.image.positionRightLateral3.name
        case .partialLeftLateral:
            return R.image.positionLeftLateral3.name
        case .partialRightLateral:
            return R.image.positionRightLateral3.name
        case .fowlers:
            return R.image.positionFowlers.name
        case .reverseTrendelenburg:
            return R.image.positionReverseTrendelenburg.name
        case [.fowlers, .reverseTrendelenburg]:
            return R.image.positionComboTrendelenburgFowlers.name
        case .trendelenburg:
            return R.image.positionTrendelenburg.name
        default:
            return R.image.positionUnknown.name
        }
    }
    
    var asData: Data {
        Data(from: rawValue.bigEndian)
    }
    
    static func fromData(_ data: Data) -> Self {
        let someData = NSData(data: data)
        var value: UInt32 = 0
        
        someData.getBytes(&value, length: 4)
        value = UInt32(bigEndian: value)
        
        return Self(rawValue: value)
    }
    
    var separate: [PositionalFlags] {
        var flagsToCheck = PositionalFlags.allFlags
        if let unknownFlagIndex = flagsToCheck.firstIndex(of: .unknown) {
            flagsToCheck.remove(at: unknownFlagIndex)
        }
        
        return flagsToCheck.filter { self.contains($0) }
    }
    
    var categorize: PositionalFlagCategory {
        return PositionalFlagCategory(using: self)
    }
}

// MARK: - CustomStringConvertible
extension PositionalFlags: CustomStringConvertible {
    var description: String {
        let fullDescription = [
            (.supine, R.string.localizable.supine()),
            (.leftLateral, R.string.localizable.leftLateral()),
            (.rightLateral, R.string.localizable.rightLateral()),
            (.partialLeftLateral, R.string.localizable.partialLeftLateral()),
            (.partialRightLateral, R.string.localizable.partialRightLateral()),
            (.fowlers, R.string.localizable.fowlers()),
            (.reverseTrendelenburg, R.string.localizable.reverseTrendelenburg()),
            (.trendelenburg, R.string.localizable.trendelenburg()),
            (.walking, R.string.localizable.walking()),
        ]
        .compactMap { option, name in contains(option) ? name : nil }
        .joined(separator: "/")
        
        return fullDescription.isEmpty ? R.string.localizable.unknown() : fullDescription
    }
}
