//
//  FacilityTurningProtocols.swift
//  SensorSuiteUMM
//
//  Created by Josh Franco on 12/9/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

class FacilityTurningProtocols: Codable {
    
    static var turnProtocol: TurnProtocol = UserDefaults.standard.turnProtocol {
        didSet {
            UserDefaults.standard.turnProtocol = turnProtocol
        }
    }
    static var complianceAngle: ComplianceAngle = UserDefaults.standard.complianceAngle! {
        didSet {
            UserDefaults.standard.complianceAngle = complianceAngle
        }
    }
    static var isComplianceEnabled: Bool = UserDefaults.standard.isComplianceEnabled {
        didSet {
            UserDefaults.standard.isComplianceEnabled = isComplianceEnabled
        }
    }
    static var isTurnProtocolEnabled: Bool = UserDefaults.standard.isTurnProtocolEnabled {
        didSet {
            UserDefaults.standard.isTurnProtocolEnabled = isTurnProtocolEnabled
        }
    }
    static var timeToTurnThreshold: Int = 660
    static var notComplyingThreshold: Int = 600

    let description: String
    let turningSequence: [PositionalFlagCategory]
    let positionsToAvoid: [PositionalFlagCategory]
    
    // MARK: - Init
    private init(description: String, positionsToAvoid: [PositionalFlagCategory]) {
        self.description = description
        self.turningSequence = [.left, .supine, .right]
        self.positionsToAvoid = positionsToAvoid
    }

    static func targetRollDegree(_ position: PositionalFlagCategory) -> ClosedRange<Double> {
        switch position {
        case .partialLeft:
            return (-Degrees.thirty.degrees)...(-complianceAngle.partialAngleDegree)
        case .left:
            return (-Degrees.fortyFive.degrees)...(-Degrees.thirty.degrees)
        case .partialRight:
            return (complianceAngle.partialAngleDegree)...Degrees.thirty.degrees
        case .right:
            return Degrees.thirty.degrees...Degrees.fortyFive.degrees
        case .supine:
            return (-Degrees.sixteen.degrees)...Degrees.sixteen.degrees
        case .other:
            return Degrees.oneEighty.degrees...Degrees.oneEighty.degrees
        }
    }

    static func isRollCompliance(_ targetPosition: PositionalFlagCategory, with roll: CGFloat) -> Bool {
        if targetPosition == .left {
            return (FacilityTurningProtocols.targetRollDegree(.left).contains(roll) ||
                    FacilityTurningProtocols.targetRollDegree(.partialLeft).contains(roll))
        } else if targetPosition == .right {
            return (FacilityTurningProtocols.targetRollDegree(.right).contains(roll) ||
                    FacilityTurningProtocols.targetRollDegree(.partialRight).contains(roll))
        } else {
            return FacilityTurningProtocols.targetRollDegree(targetPosition).contains(roll)
        }
    }
}

// MARK: - Equatable
extension FacilityTurningProtocols: Equatable {
    static func == (lhs: FacilityTurningProtocols, rhs: FacilityTurningProtocols) -> Bool {
        let lhsHash = lhs.description.hashValue + lhs.turningSequence.hashValue
        let rhsHash = rhs.description.hashValue + rhs.turningSequence.hashValue

        return lhsHash == rhsHash
    }
}

// MARK: - Default Protocols
extension FacilityTurningProtocols {
    static let dev = FacilityTurningProtocols(description: "Dev",
                                              positionsToAvoid: [.left, .supine, .right]
    )
    static let superShort = FacilityTurningProtocols(description: "Short",
                                                     positionsToAvoid: [.left, .supine, .right]
    )
    static let q2Turn = FacilityTurningProtocols(description: "Q2",
                                                 positionsToAvoid: [.left, .supine, .right]
    )
    static let q3Turn = FacilityTurningProtocols(description: "Q3",
                                                 positionsToAvoid: [.left, .supine, .right]
    )
    static let q4Turn = FacilityTurningProtocols(description: "Q4",
                                                 positionsToAvoid: [.left, .supine, .right]
    )
}
