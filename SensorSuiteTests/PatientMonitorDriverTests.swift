//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
@testable import SensorSuite_BMM
import XCTest

final class PatientMonitorDriverTests: XCTestCase {
    private var container: Container!
    private var activityLogRepository: MockActivityLogRepository!
    private var activityService: MockActivityLogService!
    private var firebaseLogger: MockFirebaseLogger!
    private var mqttService: MockMQTTService!
    private var patchService: MockPatchTrackingService!
    private var patientManager: MockPatientManager!
    private var rollCompliance: MockRollCompliance!
    private var sessionService: MockSessionService!
    private var updateService: MockUpdateService!
    private var userDefaults: MockUserDefaultsService!
    private var ttInfoDelegate: TTInfoDelegate!

    private var testSubject: PatientMonitorDriver!

    override func setUp() {
        super.setUp()
        container = Container()
        container.resetAll()

        activityLogRepository = MockActivityLogRepository()
        activityService = MockActivityLogService()
        firebaseLogger = MockFirebaseLogger()
        mqttService = MockMQTTService()
        patchService = MockPatchTrackingService()
        ttInfoDelegate = TTInfoDelegate()
        sessionService = MockSessionService(
            currentSession: .mock(),
            turnTrackerInfo: .mock(delegate: ttInfoDelegate)
        )
        patientManager = MockPatientManager()
        patientManager.session = sessionService
        rollCompliance = MockRollCompliance()
        updateService = MockUpdateService()
        userDefaults = MockUserDefaultsService()
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        userDefaults = nil
        updateService = nil
        ttInfoDelegate = nil
        rollCompliance = nil
        patientManager.session = nil
        patientManager = nil
        sessionService = nil
        patchService = nil
        mqttService = nil
        firebaseLogger = nil
        activityService = nil
        activityLogRepository = nil
        container = nil
    }

    func testSetTrackingToTo_True() {
        let exp0 = expectation(description: "testSetTrackingToTo_True - feed status update")
        exp0.expectedFulfillmentCount = 2
        var capturedIsTracking: Bool?
        initTestSubject(updateDataFeedStatusHandler: { isTracking in
            capturedIsTracking = isTracking
            exp0.fulfill()
        })
        let exp1 = expectation(description: "testSetTrackingToTo_True - patch tracking")
        var startPatchWasCalled = false
        sessionService.startPatchTimerHandler = {
            startPatchWasCalled = true
            exp1.fulfill()
        }
        let exp2 = expectation(description: "testSetTrackingToTo_True - roll is compliant")
        var isCompliantWasQueried = false
        rollCompliance.isCompliantHandler = { _, _ in
            isCompliantWasQueried = true
            exp2.fulfill()
            return true
        }
        testSubject.setTrackingTo(to: true)
        wait(for: [exp0, exp1, exp2], timeout: 1)
        XCTAssertTrue(testSubject.canInsert)
        XCTAssertTrue(testSubject.info?.isTracking ?? false)
        XCTAssertTrue(capturedIsTracking ?? false)
        XCTAssertTrue(startPatchWasCalled)
        XCTAssertTrue(isCompliantWasQueried)
    }

    func testSetTrackingToTo_False() {
        initTestSubject()
        testSubject.setTrackingTo(to: false)
        XCTAssertFalse(testSubject.canInsert)
        XCTAssertFalse(testSubject.info?.isTracking ?? true)
    }

    func testSetTrackingToTo_TrueTwice() {
        let exp0 = expectation(description: "testSetTrackingToTo_True - feed status update")
        exp0.expectedFulfillmentCount = 2
        var capturedIsTracking: Bool?

        let exp3 = expectation(description: "testSetTrackingToTo_True - log saved")
        exp3.expectedFulfillmentCount = 3
        var logSaveCount = 0
        var capturedLog: ALTActivityLog?
        initTestSubject(updateDataFeedStatusHandler: { isTracking in
            capturedIsTracking = isTracking
            exp0.fulfill()
        }, syncSaveHandler: { log, _, result in
            capturedLog = log
            logSaveCount += 1
            result?(.success(()))
            exp3.fulfill()
        })
        let exp1 = expectation(description: "testSetTrackingToTo_True - patch tracking")
        var startPatchWasCalled = false
        sessionService.startPatchTimerHandler = {
            startPatchWasCalled = true
            exp1.fulfill()
        }
        let exp2 = expectation(description: "testSetTrackingToTo_True - roll is compliant")
        var isCompliantCount = 0
        rollCompliance.isCompliantHandler = { _, _ in
            if isCompliantCount < 1 {
                exp2.fulfill()
            }
            isCompliantCount += 1
            return true
        }
        testSubject.setTrackingTo(to: true)
        testSubject.setTrackingTo(to: true)

        wait(for: [exp0, exp1, exp2, exp3], timeout: 2)
        XCTAssertTrue(testSubject.canInsert)
        XCTAssertTrue(testSubject.info?.isTracking ?? false)
        XCTAssertTrue(capturedIsTracking ?? false)
        XCTAssertTrue(startPatchWasCalled)
        XCTAssertTrue(isCompliantCount >= 1)

        XCTAssertEqual(logSaveCount, 3)
        XCTAssertNotNil(capturedLog)
        guard let capturedLog else {
            return
        }
        XCTAssertNil(capturedLog.id)
        XCTAssertEqual(capturedLog.actualPosition, "Other")
        XCTAssertEqual(capturedLog.startingTargetPosition, "Supine")
        XCTAssertEqual(capturedLog.endingTimeRemaining ?? -1, 0, accuracy: 1e-3)
        XCTAssertEqual(capturedLog.bmmMonitoringState, "onResume")
        XCTAssertEqual(capturedLog.bmmPauseReason, "NULL")
        XCTAssertTrue(capturedLog.isWrongPosition)
        XCTAssertEqual(capturedLog.hospitalRoomBedId, "roomBed1")
        XCTAssertEqual(
            capturedLog.mqttTopicStr,
            """
            data/TEST-FACILITY/TEST-GUID/\
            sensor/00000000-0000-0000-0000-000000000000/\
            session_observation
            """
        )
        XCTAssertFalse(capturedLog.isSynced)
        XCTAssertTrue(capturedLog.isCurrent)
        XCTAssertEqual(capturedLog.headOfBedAngle, 0)
        XCTAssertEqual(capturedLog.turnAngle, 0)
        XCTAssertEqual(capturedLog.endingTargetPosition, "Right Lateral")
        XCTAssertEqual(capturedLog.sessionId, "sessionID-1")
        XCTAssertEqual(capturedLog.patientId, "patient-id")
    }

    func testToggleTracking_initially_true() throws {
        // Toggle tracking before `setTrackingTo(to:)`
        let exp0 = expectation(description: "testToggleTracking - update feed status")
        var lastBroadcast: Date = .twenty25
        var capturedIsTracking: Bool?
        initTestSubject(updateDataFeedStatusHandler: { isTracking in
            lastBroadcast = .now
            capturedIsTracking = isTracking
            exp0.fulfill()
        })
        wait(for: [exp0], timeout: 2)
        XCTAssertFalse(testSubject.info?.isTracking ?? true)
        XCTAssertEqual(
            testSubject.lastBroadcast.timeIntervalSinceReferenceDate,
            lastBroadcast.timeIntervalSinceReferenceDate,
            accuracy: 0.001
        )
        XCTAssertNotNil(capturedIsTracking)
        XCTAssertFalse(capturedIsTracking ?? true)
        let endDate = try XCTUnwrap(testSubject.info?.endDate)
        XCTAssertEqual(
            endDate.timeIntervalSinceReferenceDate,
            lastBroadcast.timeIntervalSinceReferenceDate,
            accuracy: 2
        )
    }

    func testToggleTracking_whenRunning() throws {
        let exp0 = expectation(description: "testSetTrackingToTo_True - feed status update1")
        exp0.expectedFulfillmentCount = 2
        let exp3 = expectation(description: "testSetTrackingToTo_True - feed status update2")
        var lastBroadcast: Date = .twenty25
        var capturedIsTracking: Bool?
        var dataFeedCallCount = 0
        initTestSubject(updateDataFeedStatusHandler: { isTracking in
            lastBroadcast = .now
            capturedIsTracking = isTracking
            if dataFeedCallCount < 2 {
                exp0.fulfill()
            } else {
                exp3.fulfill()
            }
            dataFeedCallCount += 1
        })
        let exp1 = expectation(description: "testSetTrackingToTo_True - patch tracking")
        sessionService.startPatchTimerHandler = {
            exp1.fulfill()
        }
        let exp2 = expectation(description: "testSetTrackingToTo_True - roll is compliant")
        rollCompliance.isCompliantHandler = { _, _ in
            exp2.fulfill()
            return true
        }
        // GIVEN - The session is already running
        testSubject.setTrackingTo(to: true)
        wait(for: [exp0, exp1, exp2], timeout: 2)

        // WHEN - we `toggleTracking`
        testSubject.toggleTracking()
        wait(for: [exp3], timeout: 2)

        // THEN
        guard let info = testSubject.info else {
            XCTFail("Something went wrong")
            return
        }
        XCTAssertFalse(info.isTracking)
        XCTAssertEqual(
            testSubject.lastBroadcast.timeIntervalSinceReferenceDate,
            lastBroadcast.timeIntervalSinceReferenceDate,
            accuracy: 1
        )
        XCTAssertFalse(capturedIsTracking ?? true)
    }

    func testTurnAngle() {
        initTestSubject()
        testSubject.rollDegree = 52.69
        XCTAssertEqual(testSubject.turnAngle, 53)
        testSubject.rollDegree = -26.15
        XCTAssertEqual(testSubject.turnAngle, -26)
    }

    func testHeadOfBedAngle() {
        initTestSubject()
        testSubject.pitchDegree = 12.34
        XCTAssertEqual(testSubject.headOfBedAngle, 12)
        testSubject.pitchDegree = -53.74
        XCTAssertEqual(testSubject.headOfBedAngle, -54)
        testSubject.pitchDegree = -553.74
        XCTAssertEqual(testSubject.headOfBedAngle, -194)
    }

    func testPatchExpirationThreshold_sessionSet() {
        initTestSubject()
        sessionService.patchExpirationThreshold = 100
        XCTAssertEqual(testSubject.patchExpirationThreshold, 100)
    }

    func testGetInfo() {
        initTestSubject()
        let expected: TurnTrackerInfo = .mock(
            endDate: .twenty25,
            position: .right,
            remainingTime: 1.234,
            delegate: ttInfoDelegate
        )
        sessionService.turnTrackerInfo = expected
        XCTAssertEqual(testSubject.info?.remainingTime, expected.remainingTime)
        XCTAssertEqual(testSubject.info?.endDate, expected.endDate)
        XCTAssertFalse(testSubject.info?.sequence.isEmpty ?? true)
        XCTAssertNotNil(testSubject.info?.delegate)
    }

    func testStatusText() {
        initTestSubject()
        XCTAssertEqual(testSubject.statusText, "")
        testSubject.currentState = .onStart
        XCTAssertEqual(testSubject.statusText, "")
        testSubject.currentState = .onResume
        XCTAssertEqual(testSubject.statusText, "MONITORING")
        testSubject.currentState = .onPause
        XCTAssertEqual(testSubject.statusText, "PAUSED: UNKNOWN")
        testSubject.currentState = .onPause
        testSubject.pauseReason = .outOfBedMobility
        XCTAssertEqual(testSubject.statusText, "PAUSED: OUT OF BED MOBILITY")
    }

    func testIsTracking() {
        initTestSubject()
        XCTAssertFalse(testSubject.isTracking)
        sessionService.turnTrackerInfo.toggleTracking(to: true)
        XCTAssertTrue(testSubject.isTracking)
    }

    func testIsNewSession() {
        initTestSubject()
        XCTAssertTrue(testSubject.isNewSession)
    }

    func testAllPositions_initial() {
        initTestSubject()
        XCTAssertEqual(testSubject.allPositions, [PositionalFlagCategory.left, .right, .supine])
    }

    func testCanMoveToNextPosition() {
        initTestSubject()
        XCTAssertTrue(testSubject.canMoveToNextPosition)
    }

    func testTextMode() {
        initTestSubject()
        testSubject.currentState = .onPause
        XCTAssertEqual(testSubject.textMode, .paused)
        testSubject.currentState = .onStart
        XCTAssertEqual(testSubject.textMode, .countdown)
    }

    func testStartNextPosition() {
        initTestSubject()
        XCTAssertEqual(testSubject.info?.getPositionOrder(.current), .supine)
        XCTAssertEqual(testSubject.info?.getPositionOrder(.next), .right)
        testSubject.startNextPosition()
        XCTAssertEqual(testSubject.info?.getPositionOrder(.current), .right)
        XCTAssertEqual(testSubject.info?.getPositionOrder(.next), .left)
        XCTAssertFalse(testSubject.timeToTurn)
        XCTAssertFalse(testSubject.startNextPositionConfirmation)
        XCTAssertEqual(testSubject.timeInTurn, 0)
    }
}

private extension PatientMonitorDriverTests {
    func initTestSubject(
        latestActivityLogHandler: @escaping (() -> ALTActivityLog?) = { nil },
        didCrashDuringPreviousExecutionHandler: @escaping (() -> Bool) = { false },
        updateDataFeedStatusHandler: @escaping ((Bool) -> Void) = { _ in },
        syncSaveHandler: @escaping ((ALTActivityLog, DispatchQueue, ((Result<(), any Error>) -> Void)?) -> Void) = { _, _, _ in },
        mqttPublishHandler: @escaping ((Data, String, Bool, MQTTQosLevel, ((Result<String, any Error>) -> Void)?) -> Void) = { _, _, _, _, _ in },
        isWearableConnectedHandler: @escaping (() -> Bool) = { true },
        startPatchTimerHandler: @escaping (() -> Void) = { },
        isFirstLaunchHandler: @escaping (() -> Bool) = { false },
        isRollCompliantHandler: @escaping ((PositionalFlagCategory, CGFloat) -> Bool) = { _, _ in true },
        complianceAngle: ComplianceAngle = .angle20,
        turnProtocol: TurnProtocol = .Q2,
        baseStationGuid: String = "test-guid",
        facilityId: String = "test-facility",
        appleID: String = "hoth-station"
    ) {
        activityLogRepository.withLastEndDateHandler = latestActivityLogHandler
        activityLogRepository.syncSaveToDBHandler = syncSaveHandler
        mqttService.publishWithResultHandler = mqttPublishHandler
        firebaseLogger.didCrashDuringPreviousExecutionHandler = didCrashDuringPreviousExecutionHandler
        sessionService.updateDataFeedStatusHandler = updateDataFeedStatusHandler
        sessionService.isWearableConnectedHandler = isWearableConnectedHandler
        sessionService.startPatchTimerHandler = startPatchTimerHandler
        updateService.isFirstLaunchHandler = isFirstLaunchHandler
        rollCompliance.isCompliantHandler = isRollCompliantHandler
        userDefaults.complianceAngle = complianceAngle
        userDefaults.turnProtocol = turnProtocol
        userDefaults.baseStationGuid = baseStationGuid
        userDefaults.facilityId = facilityId
        userDefaults.defaultingBaseStationFromApple = appleID
        patientManager.cachePatient = .mock()
        patientManager.currentPatient = .mock()
        patientManager.turnTrackerInfo = .mock(delegate: ttInfoDelegate)

        container.activityLogRepository.register { self.activityLogRepository }
        container.activityLogService.register { self.activityService }
        container.firebaseLogger.register { self.firebaseLogger }
        container.mqttService.register { self.mqttService }
        container.patchTrackingService.register { self.patchService }
        container.patientManager.register { self.patientManager }
        container.rollCompliance.register { self.rollCompliance }
        container.updateService.register { self.updateService }
        container.userDefaults.register { self.userDefaults }

        testSubject = PatientMonitorDriver(using: patientManager, container: container)
    }
}

private extension ALTPatient {
    static func mock(
        id: String = "test-id",
        heightMeasure: Requirement = .kilograms,
        weightMeasure: Requirement = .inches,
        height: Int = 200,
        weight: Int = 100,
        hasPaceMaker: Bool = false,
        hasSternumSkinBroken: Bool = false,
        sex: ALTSex = .female,
        bmi: Double = 12,
        props: String = "props"
    ) -> ALTPatient {
        var patient = ALTPatient(
            hospitalRoomBedId: "roomBed1",
            heightIn: height,
            weightLbs: weight,
            hasPaceMaker: hasPaceMaker,
            hasSternumSkinBroken: hasSternumSkinBroken,
            sex: sex,
            bmi: bmi,
            props: props,
            id: id
        )
        patient.heightMeasurement = heightMeasure
        patient.weightMeasurement = weightMeasure
        return patient
    }
}

private extension TurnTrackerInfo {
    static func mock(
        endDate: Date? = nil,
        position: PositionalFlagCategory = .supine,
        remainingTime: TimeInterval = 0,
        delegate: TurnTrackerDelegate
    ) -> TurnTrackerInfo {
        TurnTrackerInfo(
            endDate: endDate,
            positionalFlagCategory: position,
            remainingTime: remainingTime,
            delegate: delegate
        )
    }
}

private final class TTInfoDelegate: TurnTrackerDelegate {
    let sequence: [PositionalFlagCategory]

    init(sequence: [PositionalFlagCategory] = [.left, .supine, .right]) {
        self.sequence = sequence
    }

    func getPositionSequence() -> [PositionalFlagCategory] {
        sequence
    }
}

private extension ALTSession {
    static func mock(
        _ id: String = "sessionID-1",
        patientID: String = "patient-id",
        hasEnded: Bool = false,
        turnProtocol: TurningProtocol = .superShort,
        positionsToAvoid: PositionalFlags = .walking
    ) -> ALTSession {
        ALTSession(
            patientId: patientID,
            turningProtocol: turnProtocol,
            positionsToAvoid: positionsToAvoid,
            hasEnded: hasEnded,
            id: id
        )
    }
}

private extension ALTActivityLog {
    static func mock(
        _ id: Int64? = 0,
        patientID: String = "patient0",
        sessionID: String = "session0",
        roomID: String = "room0",
        startDate: Date = .twenty25,
        endDate: Date = .twenty25(plus: 500),
        position: PositionalFlagCategory = .left,
        startPosition: PositionalFlagCategory = .supine,
        startTimeRemaining: Double = 50,
        endTimeRemaining: Double? = nil,
        monitoringState: PatientMonitorState = .onResume,
        pauseReason: PauseReason = .null,
        isWrongPosition: Bool = false,
        mqttTopicStr: String = "a/b/c/x/y/z",
        updateID: String = "update0",
        headOfBedAngle: Int? = nil,
        turnAngle: Int? = 500,
        endingTargetPosition: String? = nil,
        isCurrent: Bool = true,
        isSynced: Bool = false
    ) -> ALTActivityLog {
        ALTActivityLog(
            patientID: patientID,
            sessionID: sessionID,
            actualPositionStarted: startDate,
            actualPositionEnded: endDate,
            actualPosition: position,
            startingTarget: startPosition,
            startingTimeRemaining: startTimeRemaining,
            endingTimeRemaining: endTimeRemaining,
            bmmMonitoringState: monitoringState.rawValue,
            bmmPauseReason: pauseReason.rawValue,
            isWrongPosition: isWrongPosition,
            hospitalRoomBedID: roomID,
            mqttTopicStr: mqttTopicStr,
            updateID: updateID,
            headOfBedAngle: headOfBedAngle,
            turnAngle: turnAngle,
            endingTargetPosition: endingTargetPosition,
            id: id,
            isCurrent: isCurrent,
            isSynced: isSynced
        )
    }
}
