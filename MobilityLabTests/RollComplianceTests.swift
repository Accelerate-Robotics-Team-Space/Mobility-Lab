//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
@testable import MobilityLab_BMM
import XCTest

final class RollComplianceTests: XCTestCase {
    var container: Container!
    var userDefaults: MockUserDefaultsService!
    var testSubject: RollCompliance!

    override func setUp() {
        super.setUp()
        container = .init()
        container.resetAll()

        userDefaults = MockUserDefaultsService()
        container.userDefaults.register { self.userDefaults }

        testSubject = RollCompliance(container: container)
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        userDefaults = nil
        container = nil
    }

    func testTargetRollDegree_20DegreeCompliance() {
        userDefaults.complianceAngle = .angle20

        let partialLeftRange = testSubject.targetRollDegree(.partialLeft)
        let leftRange = testSubject.targetRollDegree(.left)
        let partialRightRange = testSubject.targetRollDegree(.partialRight)
        let rightRange = testSubject.targetRollDegree(.right)
        let supineRange = testSubject.targetRollDegree(.supine)
        let otherRange = testSubject.targetRollDegree(.other)

        XCTAssertEqual(partialLeftRange.lowerBound, -30)
        XCTAssertEqual(partialLeftRange.upperBound, -20)
        XCTAssertEqual(leftRange.lowerBound, -45)
        XCTAssertEqual(leftRange.upperBound, -30)
        XCTAssertEqual(partialRightRange.lowerBound, 20)
        XCTAssertEqual(partialRightRange.upperBound, 30)
        XCTAssertEqual(rightRange.lowerBound, 30)
        XCTAssertEqual(rightRange.upperBound, 45)
        XCTAssertEqual(supineRange.lowerBound, -16)
        XCTAssertEqual(supineRange.upperBound, 16)
        XCTAssertEqual(otherRange.lowerBound, 180)
        XCTAssertEqual(otherRange.upperBound, 180)
    }

    func testTargetRollDegree_25DegreeCompliance() {
        userDefaults.complianceAngle = .angle25

        let partialLeftRange = testSubject.targetRollDegree(.partialLeft)
        let leftRange = testSubject.targetRollDegree(.left)
        let partialRightRange = testSubject.targetRollDegree(.partialRight)
        let rightRange = testSubject.targetRollDegree(.right)
        let supineRange = testSubject.targetRollDegree(.supine)
        let otherRange = testSubject.targetRollDegree(.other)

        XCTAssertEqual(partialLeftRange.lowerBound, -30)
        XCTAssertEqual(partialLeftRange.upperBound, -25)
        XCTAssertEqual(leftRange.lowerBound, -45)
        XCTAssertEqual(leftRange.upperBound, -30)
        XCTAssertEqual(partialRightRange.lowerBound, 25)
        XCTAssertEqual(partialRightRange.upperBound, 30)
        XCTAssertEqual(rightRange.lowerBound, 30)
        XCTAssertEqual(rightRange.upperBound, 45)
        XCTAssertEqual(supineRange.lowerBound, -16)
        XCTAssertEqual(supineRange.upperBound, 16)
        XCTAssertEqual(otherRange.lowerBound, 180)
        XCTAssertEqual(otherRange.upperBound, 180)
    }

    func testTargetRollDegree_30DegreeCompliance() {
        userDefaults.complianceAngle = .angle30

        let partialLeftRange = testSubject.targetRollDegree(.partialLeft)
        let leftRange = testSubject.targetRollDegree(.left)
        let partialRightRange = testSubject.targetRollDegree(.partialRight)
        let rightRange = testSubject.targetRollDegree(.right)
        let supineRange = testSubject.targetRollDegree(.supine)
        let otherRange = testSubject.targetRollDegree(.other)

        XCTAssertEqual(partialLeftRange.lowerBound, -30)
        XCTAssertEqual(partialLeftRange.upperBound, -30)
        XCTAssertEqual(leftRange.lowerBound, -45)
        XCTAssertEqual(leftRange.upperBound, -30)
        XCTAssertEqual(partialRightRange.lowerBound, 30)
        XCTAssertEqual(partialRightRange.upperBound, 30)
        XCTAssertEqual(rightRange.lowerBound, 30)
        XCTAssertEqual(rightRange.upperBound, 45)
        XCTAssertEqual(supineRange.lowerBound, -16)
        XCTAssertEqual(supineRange.upperBound, 16)
        XCTAssertEqual(otherRange.lowerBound, 180)
        XCTAssertEqual(otherRange.upperBound, 180)
    }

    func testIsRollCompliant_success() {
        userDefaults.complianceAngle = .angle20

        let isCompliant = testSubject.isRollCompliance(.left, with: -27)
        XCTAssertTrue(isCompliant)
    }

    func testIsRollCompliant_failure() {
        userDefaults.complianceAngle = .angle20

        let isCompliant = testSubject.isRollCompliance(.left, with: 27)
        XCTAssertFalse(isCompliant)
    }
}
