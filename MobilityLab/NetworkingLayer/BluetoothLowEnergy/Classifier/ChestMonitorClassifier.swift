//
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

/// Classifies position based on monitor being affixed to the patient's chest using the force of gravity as the
/// most significant factor.
///
/// - Note:
/// It is assumed that the remote sensor has done a decent job of separating user acceleration from the
/// acceleration caused by gravity (9.8 m/s^2).  This classifier only works for relatively steady patients.  If a
/// patient is moving in such a way as to experience lots of G-forces (e.g. in a car, on a helicopter, etc) this
/// classifier will not work.
///
/// - Note:
/// Due to the datapoints that can be gathered with just a single sensor, we cannot tell apart Fowler's Position
/// vs. Reverse Trandelenburg.  These positions will be reported together.
///
/// - See Also: [PositionsFlags](x-source-tag://PositionsFlags)
struct ChestMonitorClassifier {
    let complianceAngle: ComplianceAngle

    init(complianceAngle: ComplianceAngle) {
        self.complianceAngle = complianceAngle
    }

    private var leftLowerBound: Double {
        switch complianceAngle {
        case .angle20, .angle25:
            Degrees.thirty.radians
        case .angle30:
            Degrees.thirtyMinus.radians
        }
    }

    private var leftSideRollAttitudeRange: ClosedRange<Double> {
        leftLowerBound...Degrees.fortyFive.radians
    }

    private var partialLeftSideRollAttitudeRange: ClosedRange<Double> {
        complianceAngle.partialLeftAngleRange
    }

    private var rightSideRollAttitudeRange: ClosedRange<Double> {
        leftSideRollAttitudeRange.negated()
    }

    private var partialRightSideRollAttitudeRange: ClosedRange<Double> {
        complianceAngle.partialRightAngleRange
    }

    private var supineRollAttitudeRange: ClosedRange<Double> {
        (-Degrees.sixteen.radians)...Degrees.sixteen.radians
    }

    private var fowlers: [ClosedRange<Double>] {
        [
            (-0.05)...0.2,    // X
            (-0.6)...(-0.09), // Y
            (-1.0)...(-0.85), // Z
        ]
    }

    func position(from dataPoint: DataPoint) -> PositionalFlags {
        if leftSideRollAttitudeRange.contains(dataPoint.rollAttitude) {
            .leftLateral
        } else if partialLeftSideRollAttitudeRange.contains(dataPoint.rollAttitude) {
            .partialLeftLateral
        } else if rightSideRollAttitudeRange.contains(dataPoint.rollAttitude) {
            .rightLateral
        } else if partialRightSideRollAttitudeRange.contains(dataPoint.rollAttitude) {
            .partialRightLateral
        } else if dataPoint.gravityVector.array.all(in: fowlers) {
            [.fowlers, .reverseTrendelenburg]
        } else if supineRollAttitudeRange.contains(dataPoint.rollAttitude),
                  dataPoint.zGravity < 0 {
            .supine
        } else {
            .unknown
        }
    }
}
