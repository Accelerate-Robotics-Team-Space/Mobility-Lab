//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
@testable import SensorSuite_BMM
import XCTest

final class NotificationsCellDriverTests: XCTestCase {
    var session: MockSessionService!
    var patientManager: MockPatientManager!
    var testSubject: NotificationsCellDriver!

    override func setUp() {
        session = MockSessionService(currentSession: .mock(), turnTrackerInfo: .mock())
        patientManager = MockPatientManager()
        patientManager.session = self.session
        testSubject = NotificationsCellDriver(using: patientManager)
    }

    override func tearDown() {
        testSubject = nil
        patientManager = nil
        session = nil
    }

    func testNotificationsUpdated() {
        // GIVEN - that the notifications array should initially be empty
        XCTAssertTrue(session.notificationsArr.isEmpty)
        XCTAssertTrue(testSubject.notifications.isEmpty)

        // WHEN - the session's delegate updates
        session.notificationDelegate?.notificationsUpdated([.noWearable, .noWearable])

        // THEN - we expect the update to be reflected in the test subject's notifications array
        XCTAssertEqual(testSubject.notifications.count, 2)
        XCTAssertEqual(testSubject.notifications.first, .noWearable)
        XCTAssertEqual(testSubject.notifications.last, .noWearable)
    }
}

private extension ALTSession {
    static func mock() -> ALTSession {
        ALTSession(
            patientId: "patient1",
            turningProtocol: .superShort,
            positionsToAvoid: .trendelenburg,
            id: "session-id"
        )
    }
}

private extension TurnTrackerInfo {
    static func mock() -> TurnTrackerInfo {
        TurnTrackerInfo(
            endDate: .referenceDate,
            positionalFlagCategory: .left,
            remainingTime: 500,
            delegate: nil
        )
    }
}
