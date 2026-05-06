//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
@testable import SensorSuite_BMM
import XCTest

final class NotificationCenterServiceTests: XCTestCase {
    var rawNotificationCenter: NotificationCenter!
    var testSubject: NotificationCenterService!
    let exp0: XCTestExpectation = .init(description: "NotificationCenterTests0")
    let exp1: XCTestExpectation = .init(description: "NotificationCenterTests1")
    var notification0: Notification?
    var notification1: Notification?

    override func setUpWithError() throws {
        rawNotificationCenter = .default
        testSubject = NotificationCenterService(notificationCenter: rawNotificationCenter)
    }

    override func tearDownWithError() throws {
        testSubject = nil
        rawNotificationCenter = nil
        notification0 = nil
        notification1 = nil
    }

    @objc func handler0(_ notification: Notification) {
        self.notification0 = notification
        exp0.fulfill()
    }

    @objc func handler1(_ notification: Notification) {
        self.notification1 = notification
        exp1.fulfill()
    }

    func testPostNotification() {
        let exp = XCTestExpectation(description: #function)
        var notificationName: Notification.Name?
        rawNotificationCenter.addObserver(forName: .test0, object: nil, queue: nil) { notification in
            notificationName = notification.name
            exp.fulfill()
        }

        testSubject.post(name: .test0, userInfo: nil)

        wait(for: [exp], timeout: 1)
        XCTAssertEqual(notificationName, .test0)
    }

    func testObserveNotification() {
        testSubject.addObserver(self, selector: #selector(handler0), name: .test1, object: nil)

        testSubject.post(name: .test1, userInfo: nil)

        wait(for: [exp0], timeout: 1)
        XCTAssertNotNil(notification0)
        XCTAssertEqual(notification0?.name, .test1)
    }

    func testRemoveObserver() {
        testSubject.addObserver(self, selector: #selector(handler1), name: .test2, object: nil)

        testSubject.post(name: .test2, userInfo: nil)

        wait(for: [exp1], timeout: 1)
        XCTAssertNotNil(notification1)
        XCTAssertEqual(notification1?.name, .test2)

        notification1 = nil

        testSubject.removeObserver(self, name: .test0, object: nil)

        testSubject.post(name: .test2, userInfo: nil)

        XCTAssertNil(notification1)
    }
}

private extension Notification.Name {
    static let test0 = Notification.Name(rawValue: "test0")
    static let test1 = Notification.Name(rawValue: "test0")
    static let test2 = Notification.Name(rawValue: "test0")
}
