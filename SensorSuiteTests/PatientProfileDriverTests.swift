//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
@testable import SensorSuite_BMM
import XCTest

final class PatientProfileDriverTests: XCTestCase {

    var patientManager: MockPatientManager!
    var sessionService: MockSessionService!
    var testSubject: PatientProfileDriver!

    override func setUp() {
        super.setUp()
        sessionService = MockSessionService(currentSession: .mock(), turnTrackerInfo: .mock())
        patientManager = MockPatientManager()
        patientManager.session = sessionService
        patientManager.cachePatient = .mock()
        patientManager.currentPatient = .mock()
        let container = Container()
        container.resetAll()

        testSubject = PatientProfileDriver(manager: patientManager, container: container)
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        patientManager = nil
        sessionService = nil
    }

    func testInit() {
        XCTAssertEqual(testSubject.selectedBodyType, "Endomorph")
        XCTAssertEqual(testSubject.bodyTypeIndex, 1)
        XCTAssertEqual(testSubject.heightUnit, .kilograms)
        XCTAssertEqual(testSubject.weightUnit, .inches)
        XCTAssertFalse(testSubject.hasPaceMaker!)
        XCTAssertFalse(testSubject.hasSternumSkinBroken!)
        XCTAssertEqual(testSubject.selectedHeight, "200")
        XCTAssertEqual(testSubject.selectedWeight, "100")
        XCTAssertEqual(testSubject.bmiValue, 12)
    }

    func testUpdateBMI() {
        testSubject.updateBMI()
        XCTAssertEqual(testSubject.bmiValue, 0)
        testSubject.heightUnit = .centimeters
        XCTAssertEqual(testSubject.bmiValue, 0)
        testSubject.weightUnit = .kilograms
        XCTAssertEqual(testSubject.bmiValue, 25)
        testSubject.selectedWeight = "120"
        XCTAssertEqual(testSubject.bmiValue, 30)
        testSubject.selectedHeight = "185"
        XCTAssertEqual(testSubject.bmiValue, 35.06)

        testSubject.heightUnit = .inches
        XCTAssertEqual(testSubject.bmiValue, 0)
        testSubject.weightUnit = .pounds
        XCTAssertEqual(testSubject.bmiValue, 2.46)
        testSubject.selectedWeight = "420"
        XCTAssertEqual(testSubject.bmiValue, 8.63)
        testSubject.selectedHeight = "100"
        XCTAssertEqual(testSubject.bmiValue, 29.53)
    }

    func testCanGoNext() {
        XCTAssertFalse(testSubject.canGoNext())
        testSubject.selectIndex(for: .bodyType(index: 5))
        XCTAssertFalse(testSubject.canGoNext())
        testSubject.selectIndex(for: .bodyType(index: 1))
        XCTAssertFalse(testSubject.canGoNext())
        testSubject.selectIndex(for: .sex(index: 0))
        XCTAssertTrue(testSubject.canGoNext())
    }

    func testIsHeightAndWeightValid() {
        testSubject.selectedHeight = ""
        testSubject.selectedWeight = ""
        XCTAssertTrue(testSubject.isHeightAndWeightValid())

        testSubject.selectedHeight = "100"
        testSubject.selectedWeight = "100"
        XCTAssertTrue(testSubject.isHeightAndWeightValid())

        testSubject.selectedWeight = "1501" // 682 kg
        XCTAssertFalse(testSubject.isHeightAndWeightValid())

        testSubject.selectedWeight = "100"
        testSubject.selectedHeight = "256" // 650 cm tall!
        XCTAssertFalse(testSubject.isHeightAndWeightValid())

        testSubject.weightUnit = .kilograms
        testSubject.heightUnit = .centimeters
        XCTAssertTrue(testSubject.isHeightAndWeightValid())

        testSubject.selectedHeight = "649" // 649 cm  tall!
        XCTAssertFalse(testSubject.isHeightAndWeightValid())
    }

    func testGoNextBtnPressed() throws {
        let exp0 = expectation(description: "testGoNextBtnPressed - profile updated")
        var capturedPatient0: MockPatientManager.UpdatePatientProfileType?
        patientManager.updatePatientProfileHandler = { profile in
            capturedPatient0 = profile
            exp0.fulfill()
        }
        let exp1 = expectation(description: "testGoNextBtnPressed - button completion")
        var handler0Called = false
        let handler0: (() -> Void) = {
            handler0Called = true
            exp1.fulfill()
        }

        // Set the `sexIndex`
        testSubject.selectIndex(for: .sex(index: 0))

        testSubject.goNextBtnPress(completion: handler0)

        wait(for: [exp0, exp1], timeout: 2)

        XCTAssertTrue(handler0Called)
        let patient = try XCTUnwrap(capturedPatient0)
        XCTAssertEqual(patient.0, "test-id") // id
        XCTAssertEqual(patient.1, 200) // height
        XCTAssertEqual(patient.2, 100) // weight
        XCTAssertFalse(patient.3) // hasPacemaker
        XCTAssertFalse(patient.4) // hasSternumSkinBroken
        XCTAssertEqual(patient.5, .male) // sex
        XCTAssertEqual(patient.6, 1.7575) // bmi
        XCTAssertEqual(patient.7, #"{"avoid":""}"#) // props
        XCTAssertEqual(patient.8, "") // sensorLocation

        sessionService.posToAvoidArr = [.left, .supine]

        let exp2 = expectation(description: "testGoNextBtnPressed - profile updated - 2")
        var capturedPatient1: MockPatientManager.UpdatePatientProfileType?
        patientManager.updatePatientProfileHandler = { profile in
            capturedPatient1 = profile
            exp2.fulfill()
        }

        let exp3 = expectation(description: "testGoNextBtnPressed - button completion - 2")
        let handler1: (() -> Void) = {
            exp3.fulfill()
        }

        testSubject.goNextBtnPress(completion: handler1)

        wait(for: [exp2, exp3], timeout: 2)

        XCTAssertEqual(capturedPatient1?.7, #"{"avoid":"LS"}"#) // props
    }

    func testGetSexIndex() {
        XCTAssertEqual(testSubject.getSexIndexFromDescription(description: "Male"), 0)
        XCTAssertEqual(testSubject.getSexIndexFromDescription(description: "Female"), 1)
        XCTAssertEqual(testSubject.getSexIndexFromDescription(description: "Other"), 2)
        XCTAssertEqual(testSubject.getSexIndexFromDescription(description: "Decline to Answer"), 3)
        XCTAssertEqual(testSubject.getSexIndexFromDescription(description: "nonsense"), -1)
    }

    func testGetBodyTypeIndex() {
        XCTAssertEqual(testSubject.getBodyTypeIndexFromDescription(description: "Ectomorph"), 0)
        XCTAssertEqual(testSubject.getBodyTypeIndexFromDescription(description: "Endomorph"), 1)
        XCTAssertEqual(testSubject.getBodyTypeIndexFromDescription(description: "Mesomorph"), 2)
        XCTAssertEqual(testSubject.getBodyTypeIndexFromDescription(description: "nonsense"), -1)
    }
}

private extension ALTPatient {
    static func mock(
        heightMeasure: Requirement = .kilograms,
        weightMeasure: Requirement = .inches
    ) -> ALTPatient {
        var patient = ALTPatient(
            hospitalRoomBedId: "roomBed1",
            heightIn: 200,
            weightLbs: 100,
            hasPaceMaker: false,
            hasSternumSkinBroken: false,
            sex: .female,
            bmi: 12,
            props: "props",
            id: "test-id"
        )
        patient.heightMeasurement = heightMeasure
        patient.weightMeasurement = weightMeasure
        return patient
    }
}

private extension TurnTrackerInfo {
    static func mock() -> TurnTrackerInfo {
        TurnTrackerInfo(
            endDate: nil,
            positionalFlagCategory: .supine,
            remainingTime: 0,
            delegate: nil
        )
    }
}

private extension ALTSession {
    static func mock() -> ALTSession {
        ALTSession(
            patientId: "mock-session-id",
            turningProtocol: .superShort,
            positionsToAvoid: .walking
        )
    }
}
