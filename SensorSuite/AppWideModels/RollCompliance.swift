//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol RollComplianceProtocol {
    func targetRollDegree(_ position: PositionalFlagCategory) -> ClosedRange<Double>
    func isRollCompliance(_ targetPosition: PositionalFlagCategory, with roll: CGFloat) -> Bool
}

extension Container {
    var rollCompliance: Factory<RollComplianceProtocol> {
        self { RollCompliance() }.cached
    }
}

final class RollCompliance: RollComplianceProtocol {
    private let container: Container
    private let userDefaults: BMMUserDefaultsServiceProtocol

    init(container: Container = .shared) {
        self.container = container
        self.userDefaults = container.userDefaults.resolve()
    }

    func targetRollDegree(_ position: PositionalFlagCategory) -> ClosedRange<Double> {
        switch position {
        case .partialLeft:
            return (-Degrees.thirty.degrees)...(-userDefaults.complianceAngle!.partialAngleDegree)
        case .left:
            return (-Degrees.fortyFive.degrees)...(-Degrees.thirty.degrees)
        case .partialRight:
            return userDefaults.complianceAngle!.partialAngleDegree...Degrees.thirty.degrees
        case .right:
            return Degrees.thirty.degrees...Degrees.fortyFive.degrees
        case .supine:
            return (-Degrees.sixteen.degrees)...Degrees.sixteen.degrees
        case .other:
            return Degrees.oneEighty.degrees...Degrees.oneEighty.degrees
        }
    }

    func isRollCompliance(_ targetPosition: PositionalFlagCategory, with roll: CGFloat) -> Bool {
        if targetPosition == .left {
            return (targetRollDegree(.left).contains(roll) ||
                    targetRollDegree(.partialLeft).contains(roll))
        } else if targetPosition == .right {
            return (targetRollDegree(.right).contains(roll) ||
                    targetRollDegree(.partialRight).contains(roll))
        } else {
            return targetRollDegree(targetPosition).contains(roll)
        }
    }
}
