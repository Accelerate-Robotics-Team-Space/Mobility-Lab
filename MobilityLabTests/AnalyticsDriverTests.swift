//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
@testable import MobilityLab_BMM
import XCTest

final class AnalyticsDriverTests: XCTestCase {
    enum Error: Swift.Error {
        case test
    }

    private var container: Container!
    private var patientManager: MockPatientManager!
    private var activityLogService: MockActivityLogService!
    private var activityLogRepository: MockActivityLogRepository!
    private var rawNotificationCenter: NotificationCenter!
    private var notificationCenter: NotificationCenterService!
    private var sessionRepository: MockSessionRepository!

    private var testSubject: AnalyticsDriver!
    private var analyticsActivityViewModel: AnalyticsActivityViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        container = .init()
        container.resetAll()
        cancellables = []

        activityLogService = MockActivityLogService()
        activityLogRepository = MockActivityLogRepository()
        sessionRepository = MockSessionRepository()
        rawNotificationCenter = NotificationCenter()
        notificationCenter = NotificationCenterService(notificationCenter: rawNotificationCenter)
        patientManager = MockPatientManager()

        container.activityLogService.register { self.activityLogService }
        container.activityLogRepository.register { self.activityLogRepository }
        container.sessionRepository.register { self.sessionRepository }
        container.notificationCenter.register { self.notificationCenter }
        container.patientManager.register { self.patientManager }
    }

    override func tearDown() {
        super.tearDown()
        cancellables.forEach { $0.cancel() }
        testSubject = nil
        patientManager = nil
        notificationCenter = nil
        rawNotificationCenter = nil
        sessionRepository = nil
        activityLogService = nil
        analyticsActivityViewModel = nil
        cancellables = nil
    }

    func testUpdateCurrentPosition() async {
        // GIVEN - an AnalyticsActivityViewModel with analytics data
        let now = Date()
        let supine: [ALTActivityLog] = [
            .mock(id: 2, start: now, end: now.adding(20), position: .supine),
            .mock(id: 3, start: now.adding(20), end: now.adding(40), position: .supine),
            .mock(id: 4, start: now.adding(40), end: now.adding(60), position: .supine),
            .mock(id: 5, start: now.adding(60), end: now.adding(80), position: .supine),
        ]
        let left: [ALTActivityLog] = [
            .mock(id: 6, start: now.adding(80), end: now.adding(100), position: .left),
            .mock(id: 7, start: now.adding(100), end: now.adding(120), position: .left),
            .mock(id: 8, start: now.adding(120), end: now.adding(140), position: .left),
            .mock(id: 9, start: now.adding(140), end: now.adding(160), position: .left),
        ]

        let exp0 = expectation(description: "testUpdateCurrentPosition - positionDurations updated")
        let activityHandler: (() -> StorageValuePublisher<[ALTActivityLog]>) = {
            StaticStorageValuePublisher(supine + left)
        }

        let positionsHandler: (([String: [PositionalFlagCategory: Int64]]) -> Void) = { _ in
            exp0.fulfill()
        }

        initTestSubject(activityPublisherHandler: activityHandler, positionDurationsUpdated: positionsHandler)

        let exp1 = expectation(description: "testUpdateCurrentPosition - current position updated")
        exp1.expectedFulfillmentCount = 2
        let cancellable0 = testSubject.$positionDurations.sink { _ in
            exp1.fulfill()
        }

        await fulfillment(of: [exp0], timeout: 6)

        // WHEN - the position is updated
        testSubject.updateCurrentPosition()

        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        XCTAssertEqual(formatter.string(from: testSubject.firstDay), formatter.string(from: now))

        // Wait again as the `timeLineDict` update is done async on main thread
        await fulfillment(of: [exp1], timeout: 4)

        // THEN - the time line dictionary will not be empty
        XCTAssertFalse(testSubject.positionDurations.isEmpty)
        cancellable0.cancel()
    }

    func testGoForwards() {
        let expectedDate: Date = .now
        initTestSubject()
        XCTAssertEqual(
            testSubject.selectedDate.timeIntervalSinceReferenceDate,
            expectedDate.timeIntervalSinceReferenceDate,
            accuracy: 1e-2
        )

        testSubject.goForward()

        XCTAssertEqual(
            testSubject.selectedDate.timeIntervalSinceReferenceDate,
            expectedDate.addingTimeInterval(.secondsPerDay).timeIntervalSinceReferenceDate,
            accuracy: 1e-2
        )
    }

    func testGoBackards() {
        let expectedDate: Date = .now
        initTestSubject()
        XCTAssertEqual(
            testSubject.selectedDate.timeIntervalSinceReferenceDate,
            expectedDate.timeIntervalSinceReferenceDate,
            accuracy: 1e-2
        )

        testSubject.goBackward()

        XCTAssertEqual(
            testSubject.selectedDate.timeIntervalSinceReferenceDate,
            expectedDate.addingTimeInterval(-.secondsPerDay).timeIntervalSinceReferenceDate,
            accuracy: 1e-2
        )
    }

    func testPausedDuration() async {
        // GIVEN - an AnalyticsActivityViewModel with analytics data
        let now = Date()
        let paused: [ALTActivityLog] = [
            .mock(id: 2, start: now, end: now.adding(20), state: .onPause),
            .mock(id: 3, start: now.adding(20), end: now.adding(40), state: .onPause),
            .mock(id: 4, start: now.adding(40), end: now.adding(60), state: .onPause),
            .mock(id: 5, start: now.adding(60), end: now.adding(80), state: .onPause),
        ]
        let resumed: [ALTActivityLog] = [
            .mock(id: 6, start: now.adding(80), end: now.adding(100), state: .onResume),
            .mock(id: 7, start: now.adding(100), end: now.adding(120), state: .onResume),
            .mock(id: 8, start: now.adding(120), end: now.adding(140), state: .onResume),
            .mock(id: 9, start: now.adding(140), end: now.adding(160), state: .onResume),
        ]

        let exp0 = expectation(description: "testPausedDuration - activities updated")
        exp0.expectedFulfillmentCount = 2

        let exp1 = expectation(description: "testPausedDuration - dict updated")

        let activityPublisherhandler: (() -> StorageValuePublisher<[ALTActivityLog]>) = {
            StaticStorageValuePublisher(paused + resumed)
        }

        let activityUpdateHandler: (([String: [Int64: ALTActivityLog]]) -> Void) = { _ in
            exp0.fulfill()
        }

        initTestSubject(activityPublisherHandler: activityPublisherhandler, activitiesByDateUpdated: activityUpdateHandler)
        await fulfillment(of: [exp0], timeout: 4)

        var timelineUpdateCount = 0
        let cancellable = testSubject.$timeLineDict.dropFirst().sink { _ in
            timelineUpdateCount += 1
            exp1.fulfill()
        }

        // WHEN - we call `updateTimeLine`
        testSubject.updateTimeLine()

        let startOfDay = Calendar.current.startOfDay(for: now)
        let durations: [Double] = paused
            .map {
                // time intervals since midnight
                ($0.actualPositionStarted.timeIntervalSince(startOfDay), $0.actualPositionEnded.timeIntervalSince(startOfDay))
            }
            .map {
                // Normalise => Limit/Clamp: start time to positive, end time to number of seconds in 1 day
                ($0 < 0 ? 0 : $0, $1 > .secondsPerDay ? .secondsPerDay : $1)
            }
            .map {
                // duration = end - start
                $1 - $0
            }
        let expected = Int64(durations.reduce(0.0, +) * 1_000) // pausedDuration uses a factor of 1,000 in the final result

        await fulfillment(of: [exp1], timeout: 4)
        try? await Task.sleep(nanoseconds: 8_000)

        // THEN - the calculated pause duration should be as expected
        XCTAssertEqual(testSubject.pausedDuration, expected)
        XCTAssertEqual(timelineUpdateCount, 1)
        cancellable.cancel()
    }
}

private extension AnalyticsDriverTests {
    func initTestSubject(
        lastSessionHandler: @escaping (() async -> ALTSession?) = { .mock(id: "session1", patientID: "123") },
        resumeHandler: @escaping ((String?) -> Void) = { _ in },
        activityPublisherHandler: @escaping (() -> StorageValuePublisher<[ALTActivityLog]>) = { StaticStorageValuePublisher([ALTActivityLog]()) },
        activitiesByDateUpdated: (([String: [Int64: ALTActivityLog]]) -> Void)? = nil,
        positionDurationsUpdated: (([String: [PositionalFlagCategory: Int64]]) -> Void)? = nil
    ) {
        sessionRepository.getLastSessionHandler = lastSessionHandler
        activityLogService.resumeHandler = resumeHandler
        activityLogRepository.activityPublisherHandler = activityPublisherHandler
        testSubject = AnalyticsDriver(using: patientManager, container: container)
        self.analyticsActivityViewModel = testSubject.analyticsActivityViewModel

        testSubject.analyticsActivityViewModel
            .$activitiesByDate
            .sink {
                activitiesByDateUpdated?($0)
            }
            .store(in: &cancellables)

        testSubject.analyticsActivityViewModel
            .$positionDurationsByDate
            .dropFirst()
            .sink {
                positionDurationsUpdated?($0)
            }
            .store(in: &cancellables)
    }
}

private extension ALTSession {
    static func mock(
        id: String?,
        patientID: String,
        hasEnded: Bool = false,
        turningProtocol: TurningProtocol = .superShort,
        positionsToAvoid: PositionalFlags = .trendelenburg
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

private extension ALTActivityLog {
    static func mock(
        id: Int64?,
        start: Date,
        end: Date,
        patientID: String = "patient1",
        sessionID: String = "session1",
        position: PositionalFlagCategory = .supine,
        target: PositionalFlagCategory = .supine,
        state: PatientMonitorState = .onResume
    ) -> ALTActivityLog {
        ALTActivityLog(
            patientID: patientID,
            sessionID: sessionID,
            actualPositionStarted: start,
            actualPositionEnded: end,
            actualPosition: position,
            startingTarget: target,
            startingTimeRemaining: 10,
            endingTimeRemaining: 10,
            bmmMonitoringState: state.rawValue,
            bmmPauseReason: "allow",
            isWrongPosition: false,
            hospitalRoomBedID: "id1",
            mqttTopicStr: "str",
            updateID: "str",
            headOfBedAngle: 10,
            turnAngle: 10,
            endingTargetPosition: nil,
            id: id,
            isCurrent: true,
            isSynced: false
        )
    }
}
