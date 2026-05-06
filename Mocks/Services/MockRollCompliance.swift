//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockRollCompliance: RollComplianceProtocol {
    var targetRollHandler: ((PositionalFlagCategory) -> ClosedRange<Double>)?
    var isCompliantHandler: ((PositionalFlagCategory, CGFloat) -> Bool)?

    func targetRollDegree(_ position: PositionalFlagCategory) -> ClosedRange<Double> {
        guard let targetRollHandler else {
            fatalError("targetRollHandler not set")
        }
        return targetRollHandler(position)
    }
    
    func isRollCompliance(_ targetPosition: PositionalFlagCategory, with roll: CGFloat) -> Bool {
        guard let isCompliantHandler else {
            fatalError("isCompliantHandler must be set")
        }
        return isCompliantHandler(targetPosition, roll)
    }
}

final class NullRollCompliance: RollComplianceProtocol {
    func targetRollDegree(_ position: PositionalFlagCategory) -> ClosedRange<Double> {
        fatalError("Null Service Should Not Be Used")
    }

    func isRollCompliance(_ targetPosition: PositionalFlagCategory, with roll: CGFloat) -> Bool {
        fatalError("Null Service Should Not Be Used")
    }
}
