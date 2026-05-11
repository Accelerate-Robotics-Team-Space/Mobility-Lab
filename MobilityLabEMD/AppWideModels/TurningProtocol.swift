//
//  TurningProtocol.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 12/28/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation
import SwiftUI

class TurningProtocol: ObservableObject {
    @Published var turnProtocol: TurnProtocol = .Q2
    @Published var complianceAngle: ComplianceAngle = .angle20

    // MARK: - Init
    func targetRollDegree(_ position: PositionalFlagCategory) -> ClosedRange<Double> {
        switch position {
        case .partialLeft:
            return (-Degrees.thirty.degrees)...(-complianceAngle.partialAngleDegree)
        case .left:
            return (-Degrees.fortyFive.degrees)...(-Degrees.thirty.degrees)
        case .partialRight:
            return complianceAngle.partialAngleDegree...Degrees.thirty.degrees
        case .right:
            return Degrees.thirty.degrees...Degrees.fortyFive.degrees
        case .supine:
            return (-Degrees.sixteen.degrees)...Degrees.sixteen.degrees
        case .other:
            return Degrees.oneEighty.degrees...Degrees.oneEighty.degrees
        }
    }
}

extension TurningProtocol: Equatable {
    static func == (lhs: TurningProtocol, rhs: TurningProtocol) -> Bool {
        let turnEqual = lhs.turnProtocol == rhs.turnProtocol
        let complianceEqual = lhs.complianceAngle == rhs.complianceAngle

        return turnEqual && complianceEqual
    }
}
