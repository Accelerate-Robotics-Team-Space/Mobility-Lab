//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

final class TurningProtocol: Codable, Sendable {
    let description: String
    let turningSequence: [PositionalFlagCategory]
    let positionsToAvoid: [PositionalFlagCategory]

    // MARK: - Init
    private init(description: String, positionsToAvoid: [PositionalFlagCategory]) {
        self.description = description
        self.turningSequence = [.left, .supine, .right]
        self.positionsToAvoid = positionsToAvoid
    }
}

// MARK: - Equatable
extension TurningProtocol: Equatable {
    static func == (lhs: TurningProtocol, rhs: TurningProtocol) -> Bool {
        lhs.description == rhs.description
        && Set(lhs.turningSequence) == Set(rhs.turningSequence)
        && Set(lhs.positionsToAvoid) == Set(rhs.positionsToAvoid)
    }
}

// MARK: - Default Protocols
extension TurningProtocol {
    static let dev = TurningProtocol(
        description: "Dev", // 2 hr
        positionsToAvoid: [.left, .supine, .right]
    )
    static let superShort = TurningProtocol(
        description: "Short", // 2 hr
        positionsToAvoid: [.left, .supine, .right]
    )
    static let q2Turn = TurningProtocol(
        description: "Q2", // 2 hr
        positionsToAvoid: [.left, .supine, .right]
    )
    static let q3Turn = TurningProtocol(
        description: "Q3", // 3 hr
        positionsToAvoid: [.left, .supine, .right]
    )
    static let q4Turn = TurningProtocol(
        description: "Q4", // 4 hr
        positionsToAvoid: [.left, .supine, .right]
    )
}
