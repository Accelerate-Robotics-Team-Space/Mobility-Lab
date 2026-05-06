//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
@testable import SensorSuite_BMM
import XCTest

final class NetworkMonitorTests: XCTestCase {
    var testSubject: NetworkMonitor!
    var container: Container!
    var networkPathMonitor: MockNetworkPathMonitor!
    var mqttService: MockMQTTService!
    var notificationCenter: MockNotificationCenterService!
    var cancellables: Set<AnyCancellable> = []

    override func setUpWithError() throws {
        cancellables = []
        mqttService = MockMQTTService()
        notificationCenter = MockNotificationCenterService()
        container = .init()
        container.resetAll()
        container.mqttService.register { self.mqttService }
        container.notificationCenter.register { self.notificationCenter }
        networkPathMonitor = MockNetworkPathMonitor()
        testSubject = NetworkMonitor(container, networkMonitor: networkPathMonitor)
        notificationCenter.postHandler = { _, _, _ in }
        mqttService.connectHandler = { }
    }
    
    override func tearDownWithError() throws {
        testSubject = nil
        networkPathMonitor = nil
        container = nil
        mqttService = nil
        notificationCenter = nil
    }

    func testStartOnQueue() {
        // GIVEN - a network monitor configured with a queue capture
        let exp = XCTestExpectation(description: #function)
        var queue: DispatchQueue?
        networkPathMonitor.queueHandler = { cue in
            queue = cue
            exp.fulfill()
        }

        // WHEN - start is invoked
        testSubject.start()

        // THEN - the monitor should start on the expected queue
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(networkPathMonitor.isStartCalled)
        XCTAssertTrue(networkPathMonitor.isStarted)
        XCTAssertEqual(queue?.label, "Network-Monitor")
    }

    func testStop() {
        // GIVEN - a started monitor
        testSubject.start()

        // WHEN - stop is invoked
        testSubject.stop()

        // THEN - the monitor should cancel and not be started
        XCTAssertTrue(networkPathMonitor.isCancelCalled)
        XCTAssertFalse(networkPathMonitor.isStarted)
    }

    func testIsConnected() {
        // GIVEN - the initial state
        // THEN - the status should be 'not connected'
        XCTAssertFalse(testSubject.isConnected)
        XCTAssertFalse(testSubject.isNetworkAvailable)

        // WHEN the status is updated to `.unsatisfied`
        networkPathMonitor.simulate(status: .unsatisfied)
        // THEN - the status should be 'not connected'
        XCTAssertFalse(testSubject.isConnected)
        XCTAssertFalse(testSubject.isNetworkAvailable)

        // WHEN the status is updated to `.requiresConnection`
        networkPathMonitor.simulate(status: .requiresConnection)
        // THEN - the status should be 'not connected'
        XCTAssertFalse(testSubject.isConnected)
        XCTAssertFalse(testSubject.isNetworkAvailable)

        // WHEN the status is updated to `.satisfied`
        networkPathMonitor.simulate(status: .satisfied)
        // THEN - the status should be 'connected'
        XCTAssertTrue(testSubject.isConnected)
        XCTAssertTrue(testSubject.isNetworkAvailable)
    }

    func testIsConnectedPublisher() {
        // GIVEN - initial state and subscribers for the first four publications
        XCTAssertFalse(testSubject.isConnected)
        XCTAssertEqual(networkPathMonitor.currentNetworkStatus, .unsatisfied)
        var cancellable0: AnyCancellable?
        var cancellable1: AnyCancellable?
        var cancellable2: AnyCancellable?
        var cancellable3: AnyCancellable?

        let expInitial = XCTestExpectation(description: "Network status published - initial")
        var isConnected0: Bool?
        cancellable0 = testSubject.isConnectedPublisher
            .sink { value in
                isConnected0 = value
                expInitial.fulfill()
                cancellable0?.cancel()
            }

        let exp1 = XCTestExpectation(description: "Network status published - after first change")
        var isConnected1: Bool?
        cancellable1 = testSubject.isConnectedPublisher
            .dropFirst()
            .sink { value in
                isConnected1 = value
                exp1.fulfill()
                cancellable1?.cancel()
            }

        let exp2 = XCTestExpectation(description: "Network status published - after second change")
        var isConnected2: Bool?
        cancellable2 = testSubject.isConnectedPublisher
            .dropFirst(2)
            .sink { value in
                isConnected2 = value
                exp2.fulfill()
                cancellable2?.cancel()
            }

        let exp3 = XCTestExpectation(description: "Network status published - after third change")
        var isConnected3: Bool?
        cancellable3 = testSubject.isConnectedPublisher
            .dropFirst(3)
            .sink { value in
                isConnected3 = value
                exp3.fulfill()
                cancellable3?.cancel()
            }

        // WHEN - the network status changes
        networkPathMonitor.simulate(status: .requiresConnection)
        networkPathMonitor.simulate(status: .satisfied)
        networkPathMonitor.simulate(status: .unsatisfied)

        // THEN - we observe the expected sequence of values
        wait(for: [expInitial], timeout: 1)
        XCTAssertEqual(isConnected0, false) // swiftlint:disable:this xct_specific_matcher

        wait(for: [exp1], timeout: 1)
        XCTAssertEqual(isConnected1, false) // swiftlint:disable:this xct_specific_matcher

        wait(for: [exp2], timeout: 1)
        XCTAssertEqual(isConnected2, true) // swiftlint:disable:this xct_specific_matcher

        wait(for: [exp3], timeout: 1)
        XCTAssertEqual(isConnected3, false) // swiftlint:disable:this xct_specific_matcher
    }

    func testNotificationsPosted() {
        // GIVEN - a post handler capturing connection/disconnection notifications
        let disconnectedExp = XCTestExpectation(description: "notification - disconnected")
        let connectedExp = XCTestExpectation(description: "notification - connected")
        var lastName: NSNotification.Name?
        notificationCenter.postHandler = { nombre, _, _ in
            lastName = nombre
            if nombre == NetworkMonitor.disconnectionNote {
                disconnectedExp.fulfill()
            } else if nombre == NetworkMonitor.connectionNote {
                connectedExp.fulfill()
            }
        }

        // WHEN - network goes offline
        networkPathMonitor.simulate(status: .unsatisfied)
        // THEN - a disconnection notification is posted
        wait(for: [disconnectedExp], timeout: 1)
        XCTAssertEqual(lastName, NetworkMonitor.disconnectionNote)

        // WHEN - network becomes available
        networkPathMonitor.simulate(status: .satisfied)
        // THEN - a connection notification is posted
        wait(for: [connectedExp], timeout: 1)
        XCTAssertEqual(lastName, NetworkMonitor.connectionNote)
    }

    func testMQTTConnects() {
        // GIVEN - a connect handler expectation
        let exp = XCTestExpectation(description: #function)
        var didConnect = false
        mqttService.connectHandler = {
            didConnect = true
            exp.fulfill()
        }

        // WHEN - network becomes available
        networkPathMonitor.simulate(status: .satisfied)

        // THEN - mqtt service connects
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(didConnect)
    }

    func testStartWithInitialSatisfiedTriggersConnectAndNotification() {
        // GIVEN - a monitor with initial status satisfied
        let satisfiedMonitor = MockNetworkPathMonitor(currentNetworkStatus: .satisfied)
        testSubject = NetworkMonitor(container, networkMonitor: satisfiedMonitor)

        let connectExp = XCTestExpectation(description: "mqtt connect on start")
        mqttService.connectHandler = { connectExp.fulfill() }

        let noteExp = XCTestExpectation(description: "connection note on start")
        notificationCenter.postHandler = { name, _, _ in
            if name == NetworkMonitor.connectionNote {
                noteExp.fulfill()
            }
        }

        // WHEN - start is invoked
        testSubject.start()

        // THEN - it connects mqtt and posts connection note
        wait(for: [connectExp, noteExp], timeout: 1.0)
        XCTAssertTrue(testSubject.isConnected)
    }

    func testRequiresConnectionPostsDisconnectedAndFlags() {
        // GIVEN - an expectation for the disconnection note
        let exp = XCTestExpectation(description: "disconnection note on requiresConnection")
        notificationCenter.postHandler = { name, _, _ in
            if name == NetworkMonitor.disconnectionNote {
                exp.fulfill()
            }
        }

        // WHEN - status becomes requiresConnection
        networkPathMonitor.simulate(status: .requiresConnection)

        // THEN - isConnected is false and disconnection note posted
        wait(for: [exp], timeout: 1.0)
        XCTAssertFalse(testSubject.isConnected)
        XCTAssertFalse(testSubject.isNetworkAvailable)
    }
}
