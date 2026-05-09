//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM
import XCTest

final class ChestMonitorClassifierTests: XCTestCase {
    struct TestsInput {
        let complianceAngle: ComplianceAngle
        let leftRoll: ClosedRange<Double>
        let leftPartialRoll: ClosedRange<Double>
        let rightRoll: ClosedRange<Double>
        let rightPartialRoll: ClosedRange<Double>
    }

    func testAngle20() {
        let inputs = TestsInput(
            complianceAngle: .angle20,
            leftRoll: 30.0001...44.9999,
            leftPartialRoll: 20.0001...29.9994,
            rightRoll: (-44.9999)...(-30.0001),
            rightPartialRoll: (-29.9994)...(-20.0001)
        )

        testAngles(inputs)
    }

    func testAngle25() {
        let inputs = TestsInput(
            complianceAngle: .angle25,
            leftRoll: 30.0001...44.9999,
            leftPartialRoll: 25.0001...29.9994,
            rightRoll: (-44.9999)...(-30.0001),
            rightPartialRoll: (-29.9994)...(-25.0001)
        )

        testAngles(inputs)
    }

    func testAngle30() {
        let inputs = TestsInput(
            complianceAngle: .angle30,
            leftRoll: 29.9999...44.9999,
            leftPartialRoll: 29.9994...29.9994, // .angle30 does not have partial angles. Dummy value
            rightRoll: (-44.9999)...(-29.9999),
            rightPartialRoll: (-29.9994)...(-29.9994) // .angle30 does not have partial angles. Dummy value
        )

        testAngles(inputs)
    }

    func testSupine() {
        // Compliance angle does not matter for determining '.supine'
        let testSubject = ChestMonitorClassifier(complianceAngle: .angle20)

        let dataPoint = DataPoint.mock(roll: -4.radians, gravity: .init(x: 0, y: 0.1, z: -1))
        XCTAssertEqual(testSubject.position(from: dataPoint), .supine)
    }

    func testFowlers_ReverseTrendelenburg() {
        // Compliance angle does not matter for determining '.fowlers / .reverseTrendelenburg'
        let testSubject = ChestMonitorClassifier(complianceAngle: .angle20)

        let dataPoint = DataPoint.mock(roll: -4.radians, gravity: .init(x: 0, y: -0.1, z: -0.9))
        let position = testSubject.position(from: dataPoint)
        XCTAssertTrue(position.contains(.fowlers))
        XCTAssertTrue(position.contains(.reverseTrendelenburg))
        XCTAssertEqual(position, [.fowlers, .reverseTrendelenburg])
    }

    func testUnknown() {
        let testSubject = ChestMonitorClassifier(complianceAngle: .angle20)

        // Patient is prone
        let dataPointProne = DataPoint.mock(roll: -4.radians, gravity: .init(x: 0, y: -0.1, z: 1))
        XCTAssertEqual(testSubject.position(from: dataPointProne), .unknown)
    }
}

private extension ChestMonitorClassifierTests {
    func testAngles(_ inputs: TestsInput, file: StaticString = #file, line: UInt = #line) {
        let testSubject = ChestMonitorClassifier(complianceAngle: inputs.complianceAngle)

        func testAngleLeftLow() {
            let dataPointLeftLow = DataPoint.mock(roll: inputs.leftRoll.lowerBound.radians)
            XCTAssertEqual(
                testSubject.position(from: dataPointLeftLow),
                .leftLateral,
                "Left Lateral Lower Bound, ComplianceAngle: \(inputs.complianceAngle.readable)",
                file: file,
                line: line
            )
        }

        func testAngleLeftHigh() {
            let dataPointLeftHigh = DataPoint.mock(roll: inputs.leftRoll.upperBound.radians)
            XCTAssertEqual(
                testSubject.position(from: dataPointLeftHigh),
                .leftLateral,
                "Left Lateral Upper Bound, ComplianceAngle: \(inputs.complianceAngle.readable)",
                file: file,
                line: line
            )
        }

        func testAnglePartialLeftLow() {
            let dataPointPartLeftLow = DataPoint.mock(roll: inputs.leftPartialRoll.lowerBound.radians)
            XCTAssertEqual(
                testSubject.position(from: dataPointPartLeftLow),
                .partialLeftLateral,
                "Partial Left Lateral Lower Bound, ComplianceAngle: \(inputs.complianceAngle.readable)",
                file: file,
                line: line
            )
        }

        func testAnglePartialLeftHigh() {
            let dataPointPartLeftHigh = DataPoint.mock(roll: inputs.leftPartialRoll.upperBound.radians)
            XCTAssertEqual(
                testSubject.position(from: dataPointPartLeftHigh),
                .partialLeftLateral,
                "Partial Left Lateral Upper Bound, ComplianceAngle: \(inputs.complianceAngle.readable)",
                file: file,
                line: line
            )
        }

        func testAngleRightLow() {
            let dataPointRightLow = DataPoint.mock(roll: inputs.rightRoll.lowerBound.radians)
            XCTAssertEqual(
                testSubject.position(from: dataPointRightLow),
                .rightLateral,
                "Right Lateral Lower Bound, ComplianceAngle: \(inputs.complianceAngle.readable)",
                file: file,
                line: line
            )
        }

        func testAngleRightHigh() {
            let dataPointRightHigh = DataPoint.mock(roll: inputs.rightRoll.upperBound.radians)
            XCTAssertEqual(
                testSubject.position(from: dataPointRightHigh),
                .rightLateral,
                "Right Lateral Upper Bound, ComplianceAngle: \(inputs.complianceAngle.readable)",
                file: file,
                line: line
            )
        }

        func testAnglePartialRightLow() {
            let dataPointPartRightLow = DataPoint.mock(roll: inputs.rightPartialRoll.lowerBound.radians)
            XCTAssertEqual(
                testSubject.position(from: dataPointPartRightLow),
                .partialRightLateral,
                "Partial Right Lateral Lower Bound, ComplianceAngle: \(inputs.complianceAngle.readable)",
                file: file,
                line: line
            )
        }

        func testAnglePartialRightHigh() {
            let dataPointPartRightHigh = DataPoint.mock(roll: inputs.rightPartialRoll.upperBound.radians)
            XCTAssertEqual(
                testSubject.position(from: dataPointPartRightHigh),
                .partialRightLateral,
                "Partial Right Lateral Upper Bound, ComplianceAngle: \(inputs.complianceAngle.readable)",
                file: file,
                line: line
            )
        }

        testAngleLeftLow()
        testAngleLeftHigh()
        testAngleRightLow()
        testAngleRightHigh()

        // .angle30 does not have partial angles
        if inputs.complianceAngle != .angle30 {
            testAnglePartialLeftLow()
            testAnglePartialLeftHigh()
            testAnglePartialRightLow()
            testAnglePartialRightHigh()
        }
    }
}

private extension Double {
    var radians: Double {
        (self * .pi) / 180
    }
}

private extension DataPoint {
    static func mock(
        roll: Double,
        gravity: DataPoint.Vector = Vector(x: 0, y: 0, z: -1)
    ) -> DataPoint {
        DataPoint(
            id: Int64.random(in: Int64.min..<Int64.max),
            xAccel: 0,
            yAccel: 0,
            zAccel: 0,
            xGravity: gravity.x,
            yGravity: gravity.y,
            zGravity: gravity.z,
            xRotationRate: 0,
            yRotationRate: 0,
            zRotationRate: 0,
            rollAttitude: roll,
            pitchAttitude: 0,
            yawAttitude: 0
        )
    }
}
