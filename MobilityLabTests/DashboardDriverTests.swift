//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
@testable import MobilityLab_BMM
import XCTest

final class DashboardDriverTests: XCTestCase {
    private var container: Container!
    private var patientManager: MockPatientManager!
    private var session: MockSessionService!
    private var mqttService: MockMQTTService!
    private var rawNotificationCenter: NotificationCenter!
    private var notificationCenter: NotificationCenterService!
    private var networkMonitor: MockNetworkMonitor!
    private var pmdsWearableDelegate: DashboardTestDelegate!
    private var testSubject: DashboardDriver!

    override func setUp() {
        container = .init()
        container.resetAll()

        pmdsWearableDelegate = DashboardTestDelegate()
        session = MockSessionService(currentSession: .mock(), turnTrackerInfo: .mock())
        session.pmdsWearableDelegate = pmdsWearableDelegate
        patientManager = MockPatientManager()
        patientManager.session = session
        mqttService = MockMQTTService()
        rawNotificationCenter = .init()
        notificationCenter = NotificationCenterService(notificationCenter: rawNotificationCenter)
        networkMonitor = MockNetworkMonitor()

        networkMonitor.isConnected = true
        patientManager.currentPatient = .mock()
        patientManager.wearables = [.mock()]
        patientManager.turnTrackerInfo = .mock()

        container.patientManager.register { self.patientManager }
        container.mqttService.register { self.mqttService }
        container.notificationCenter.register { self.notificationCenter }
        container.networkMonitor.register { self.networkMonitor }

        testSubject = DashboardDriver(
            container: container,
            calibrateDelay: 0.5,
            answerDelay: 0.5,
            oneSecondDelay: 0.5
        )
    }

    override func tearDown() {
        testSubject = nil
        networkMonitor = nil
        notificationCenter = nil
        rawNotificationCenter = nil
        mqttService = nil
        patientManager = nil
        session = nil
        pmdsWearableDelegate = nil
    }

    func testCalibrating() {
        let expLoading = expectation(description: "isLoading")
        let expFinishedLoading = expectation(description: "finishedLoading")
        var cancellable: AnyCancellable?
        var didLoad = false
        var didFinish = false
        cancellable = testSubject.$isLoading
            .dropFirst()
            .sink { isLoading in
                print("isLoading")
                if isLoading {
                    didLoad = true
                    expLoading.fulfill()
                } else {
                    didFinish = true
                    expFinishedLoading.fulfill()
                    cancellable?.cancel()
                }
            }

        session.feedRequestLocationDataPointHandler = { _, _ in }

        testSubject.calibrating(wearableId: "foo")
        wait(for: [expLoading], timeout: 2)

        session.updateFeed(.confirmed(confirmation: .success))
        wait(for: [expFinishedLoading], timeout: 2)
        XCTAssertTrue(didLoad)
        XCTAssertTrue(didFinish)
        XCTAssertTrue(testSubject.calibrated)
        cancellable = nil
    }

    func testAnswerRequest() {
        session.feedRequestLocationDataPointHandler = { _, _ in }
        session.feedRequestHandler = { _, _ in }
        let exp = expectation(description: #function)
        var wasSuccess: Bool?
        testSubject.answerRequest(true, location: .back) { success in
            wasSuccess = success
            exp.fulfill()
        }
        session.updateFeed(.confirmed(confirmation: .success))
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(wasSuccess ?? false)
    }

    func testRejectRequest() {
        let exp = expectation(description: #function)
        var unpairID: String?
        session.rejectDataFeedHandler = { id in
            unpairID = id
            exp.fulfill()
        }

        session.updateFeed(.newRequest(request: .mock()))

        testSubject.rejectRequest()
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(testSubject.instructionStep, [.openPackage])
        XCTAssertEqual(unpairID, "bob")
    }

    func testRequestDataLocation() {
        let exp0 = expectation(description: "testRequestDataLocation - location data")
        var sensorID: String?
        session.feedRequestLocationDataPointHandler = { _, id in
            sensorID = id
            exp0.fulfill()
        }
        let exp1 = expectation(description: "testRequestDataLocation - answer")
        var wasSuccess: Bool?
        testSubject.requestDataLocation(true, wearableId: "bob") { success in
            wasSuccess = success
            exp1.fulfill()
        }
        session.updateFeed(.confirmed(confirmation: .success))
        wait(for: [exp0, exp1], timeout: 1)
        XCTAssertEqual(sensorID, "bob")
        XCTAssertTrue(wasSuccess ?? false)
    }

    func testResetSwapping() {
        let exp = expectation(description: #function)
        var capturedAnswer: Bool?
        var capturedLocation: WearableLocation?
        var capturedPoint: DataPoint?
        session.swappingHandler = { answer, location, point in
            capturedAnswer = answer
            capturedLocation = location
            capturedPoint = point
            exp.fulfill()
        }
        testSubject.resetSwapping()

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(testSubject.instructionStep, [.openPackage])
        XCTAssertFalse(capturedAnswer ?? true)
        XCTAssertEqual(capturedLocation, .unknown)
        XCTAssertEqual(capturedPoint?.xAccel, 0)
        XCTAssertEqual(capturedPoint?.yAccel, 0)
        XCTAssertEqual(capturedPoint?.zAccel, 0)
        XCTAssertEqual(capturedPoint?.xGravity, 0)
        XCTAssertEqual(capturedPoint?.yGravity, 0)
        XCTAssertEqual(capturedPoint?.zGravity, 0)
        XCTAssertEqual(capturedPoint?.xRotationRate, 0)
        XCTAssertEqual(capturedPoint?.yRotationRate, 0)
        XCTAssertEqual(capturedPoint?.zRotationRate, 0)
        XCTAssertEqual(capturedPoint?.rollAttitude, 0)
        XCTAssertEqual(capturedPoint?.pitchAttitude, 0)
        XCTAssertEqual(capturedPoint?.yawAttitude, 0)
    }

    func testUnpair() {
        let exp = expectation(description: #function)
        var unpairWasCalled: Bool = false
        session.unpairHandler = {
            unpairWasCalled = true
            exp.fulfill()
        }
        testSubject.unpair()

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(testSubject.instructionStep, [.openPackage])
        XCTAssertTrue(unpairWasCalled)
    }

    func testUserDidSelectPairing() {
        let exp = expectation(description: #function)
        var pairingWasSelected = false
        pmdsWearableDelegate.pairingHandler = {
            pairingWasSelected = true
            exp.fulfill()
        }

        testSubject.userDidSelectPairing()
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(pairingWasSelected)
    }
}

private final class DashboardTestDelegate: PatientMonitorDriverWearableDelegate {
    var pairingHandler: (() -> Void)?

    func wearablePatchExpired() {
        XCTFail("Should Not Be Called")
    }
    
    func dismissBatteryLow() {
        XCTFail("Should Not Be Called")
    }
    
    func resumeMonitor() {
        XCTFail("Should Not Be Called")
    }
    
    func userDidSelectPairing() {
        pairingHandler?()
    }
}

private extension ALTPatient {
    static func mock(id: String = "id0", room: String = "room0") -> ALTPatient {
        ALTPatient(
            hospitalRoomBedId: room,
            heightIn: 20,
            weightLbs: 40,
            hasPaceMaker: false,
            hasSternumSkinBroken: false,
            sex: .other,
            bmi: 200,
            props: "curtis-electric",
            id: id
        )
    }
}

private extension Wearable {
    static func mock(
        id: String = "id-p",
        guid: UUID = .init(uuidString: "FB57EFF9-06ED-44F2-BE13-4AA0CE4340DD")!,
        bleID: UUID = .init(uuidString: "1CADDC87-E252-4484-A797-C7BED7F0709F")!,
        version: String = "1.0",
        location: WearableLocation = .leftArm
    ) -> Wearable {
        Wearable(
            id: id,
            guuid: guid,
            bleId: bleID,
            version: version,
            location: location
        )
    }
}

private extension TurnTrackerInfo {
    static func mock(
        endDate: Date? = .twenty25(plus: 10_000),
        positionalFlagCategory: PositionalFlagCategory = .supine,
        remainingTime: TimeInterval = 800,
        delegate: (any TurnTrackerDelegate)? = nil
    ) -> TurnTrackerInfo {
        TurnTrackerInfo(
            endDate: endDate,
            positionalFlagCategory: positionalFlagCategory,
            remainingTime: remainingTime,
            delegate: delegate
        )
    }
}

private extension ALTSession {
    static func mock(
        id: String = "session-0",
        patientID: String = "patient-0",
        turningProtocol: TurningProtocol = .superShort,
        positionsToAvoid: PositionalFlags = .trendelenburg,
        hasEnded: Bool = false
    ) -> ALTSession {
        ALTSession(
            patientId: patientID,
            turningProtocol: turningProtocol,
            positionsToAvoid: positionsToAvoid,
            hasEnded: hasEnded,
            id: id
        )
    }
}

private extension DataFeedConfirmation {
    static var success: DataFeedConfirmation {
        DataFeedConfirmation(wearableId: "", wearableGuuid: .init(), location: .chest, version: "")
    }

    static var failure: DataFeedConfirmation {
        DataFeedConfirmation(wearableId: "", wearableGuuid: nil, location: .chest, version: "")
    }
}

private extension DataFeedRequest {
    static func mock() -> DataFeedRequest {
        DataFeedRequest(wearableId: "bob", peripheralId: "margaret")
    }
}
