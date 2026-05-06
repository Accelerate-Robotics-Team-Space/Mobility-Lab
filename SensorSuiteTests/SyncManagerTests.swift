//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
@testable import SensorSuite_BMM
import XCTest

final class SyncManagerTests: XCTestCase {
    enum Error: Swift.Error {
        case test
    }

    var container: Container!
    var activityRepository: MockActivityLogRepository!
    var networkMonitor: MockNetworkMonitor!
    var rawNotifactionCenter: NotificationCenter!
    var notificationCenter: NotificationCenterService!
    var patientRepository: MockPatientRepository!
    var securityService: MockSecurityService!
    var nodeManager: MockNodeManager!
    var mqttService: MockMQTTService!
    var userDefaults: MockUserDefaultsService!
    var testSubject: ALTSyncManager!

    override func setUp() {
        super.setUp()
        container = .init()
        container.resetAll()

        activityRepository = MockActivityLogRepository()
        networkMonitor = MockNetworkMonitor()
        rawNotifactionCenter = NotificationCenter()
        notificationCenter = NotificationCenterService(notificationCenter: rawNotifactionCenter)
        patientRepository = MockPatientRepository()
        securityService = MockSecurityService()
        nodeManager = MockNodeManager()
        mqttService = MockMQTTService()
        userDefaults = MockUserDefaultsService()

        container.activityLogRepository.register { self.activityRepository }
        container.networkMonitor.register { self.networkMonitor }
        container.notificationCenter.register { self.notificationCenter }
        container.patientRepository.register { self.patientRepository }
        container.securityService.register { self.securityService }
        container.nodeManager.register { self.nodeManager }
        container.mqttService.register { self.mqttService }
        container.userDefaults.register { self.userDefaults }

        securityService.isDeviceRegisteredHandler = { true }
        patientRepository.fetchNonSyncedHandler = { _ in [] }
        userDefaults.turnProtocol = .Q2
        userDefaults.complianceAngle = .angle20

        testSubject = ALTSyncManager(container: container)
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        userDefaults = nil
        mqttService = nil
        nodeManager = nil
        securityService = nil
        patientRepository = nil
        notificationCenter = nil
        rawNotifactionCenter = nil
        networkMonitor = nil
        activityRepository = nil
        container = nil
    }

    func testStartSync_viaMQTT() {
        let exp0 = expectation(description: "testStartSync_viaMQTT fetch-non-synced")
        exp0.expectedFulfillmentCount = 2
        var capturedDiff: Int?
        var didPrune = false
        patientRepository.fetchNonSyncedHandler = { diff in
            Task { @MainActor in exp0.fulfill() }
            capturedDiff = diff
            return didPrune ? [] : [.mock(id: 0), .mock(id: 1), .mock(id: 2)]
        }
        networkMonitor.isConnected = true
        mqttService.status = .connected
        userDefaults.turnProtocol = .Q2
        userDefaults.complianceAngle = .angle20

        mqttService.executeOnConnectionHandler = { _ in
            XCTFail("Should not be called")
        }

        nodeManager.transmitHandler = { _, _ in
            XCTFail("Should not be called")
        }

        patientRepository.pruneHandler = { _ in
            didPrune = true
        }

        var capturedTopic: String?
        let exp1 = expectation(description: "testStartSync_viaMQTT publishedWithResultHandler - 1")
        let exp2 = expectation(description: "testStartSync_viaMQTT publishedWithResultHandler - 2")
        let exp3 = expectation(description: "testStartSync_viaMQTT publishedWithResultHandler - 3")
        var captureCount = 0
        mqttService.publishWithResultHandler = { _, topicString, _, _, result in
            capturedTopic = topicString
            if captureCount == 0 {
                exp1.fulfill()
                result?(.success("yay 0"))
            } else if captureCount == 1 {
                exp2.fulfill()
                result?(.success("yay 1"))
            } else if captureCount == 2 {
                exp3.fulfill()
                result?(.success("yay 2"))
            } else {
                XCTFail("Should not be called \(captureCount + 1) times")
                 result?(.failure(SyncManagerTests.Error.test))
            }
            captureCount += 1
        }

        patientRepository.updateIsSyncedHandler = { _, _ in
            .mock(id: captureCount)
        }

        testSubject.startSync()

        wait(for: [exp0], timeout: 2)
        XCTAssertEqual(capturedDiff, 50)

        wait(for: [exp1], timeout: 2)
        XCTAssertEqual(capturedTopic, "data/?/UNKNOWN/patient")
        wait(for: [exp2], timeout: 2)
        XCTAssertEqual(capturedTopic, "data/?/UNKNOWN/patient")
        wait(for: [exp3], timeout: 2)
        XCTAssertEqual(capturedTopic, "data/?/UNKNOWN/patient")
    }

    func testStartSync_connectMQTT() {
        let exp0 = expectation(description: "testStartSync_connectMQTT fetch-non-synced")
        exp0.expectedFulfillmentCount = 2
        var capturedDiff: Int?
        var didPrune = false
        patientRepository.fetchNonSyncedHandler = { diff in
            Task { @MainActor in exp0.fulfill() }
            capturedDiff = diff
            return didPrune ? [] : [.mock(id: 0), .mock(id: 1), .mock(id: 2)]
        }
        networkMonitor.isConnected = true
        mqttService.status = .disconnected
        userDefaults.turnProtocol = .Q2
        userDefaults.complianceAngle = .angle20

        let exp1 = expectation(description: "testStartSync_connectMQTT publishedWithResultHandler - 1")
        let exp2 = expectation(description: "testStartSync_connectMQTT publishedWithResultHandler - 2")
        let exp3 = expectation(description: "testStartSync_connectMQTT publishedWithResultHandler - 3")
        var captureCount = 0
        mqttService.executeOnConnectionHandler = { completion in
            if captureCount == 0 {
                exp1.fulfill()
                completion()
            } else if captureCount == 1 {
                exp2.fulfill()
                completion()
            } else if captureCount == 2 {
                exp3.fulfill()
                completion()
            } else {
                XCTFail("Should not be called \(captureCount + 1) times")
                completion()
            }
            captureCount += 1
        }

        nodeManager.transmitHandler = { _, _ in
            XCTFail("Should not be called")
        }

        patientRepository.pruneHandler = { _ in
            didPrune = true
        }

        mqttService.publishWithResultHandler = { _, _, _, _, _ in
            XCTFail("Should not be called")
        }

        patientRepository.updateIsSyncedHandler = { _, _ in
                .mock(id: captureCount)
        }

        testSubject.startSync()

        wait(for: [exp0], timeout: 2)
        XCTAssertEqual(capturedDiff, 50)

        wait(for: [exp1], timeout: 2)
        wait(for: [exp2], timeout: 2)
        wait(for: [exp3], timeout: 2)
        XCTAssertEqual(captureCount, 3)
    }

    func testStartSync_viaMesh() {
        let exp0 = expectation(description: "testStartSync_connectMQTT fetch-non-synced")
        exp0.expectedFulfillmentCount = 2
        var capturedDiff: Int?
        var didPrune = false
        patientRepository.fetchNonSyncedHandler = { diff in
            Task { @MainActor in exp0.fulfill() }
            capturedDiff = diff
            return didPrune ? [] : [.mock(id: 0), .mock(id: 1), .mock(id: 2)]
        }
        networkMonitor.isConnected = false
        mqttService.status = .disconnected
        userDefaults.turnProtocol = .Q2
        userDefaults.complianceAngle = .angle20

        let exp1 = expectation(description: "testStartSync_connectMQTT publishedWithResultHandler - 1")
        let exp2 = expectation(description: "testStartSync_connectMQTT publishedWithResultHandler - 2")
        let exp3 = expectation(description: "testStartSync_connectMQTT publishedWithResultHandler - 3")
        var captureCount = 0
        mqttService.executeOnConnectionHandler = { _ in
             XCTFail("Should not be called")
        }
        var capturedTransmitter: MultipeerTransmitter?
        nodeManager.transmitHandler = { transmitter, result in
            if captureCount == 0 {
                exp1.fulfill()
                capturedTransmitter = transmitter
                result(.success(()))
            } else if captureCount == 1 {
                exp2.fulfill()
                result(.success(()))
            } else if captureCount == 2 {
                exp3.fulfill()
                result(.success(()))
            } else {
                XCTFail("Should not be called \(captureCount + 1) times")
                result(.success(()))
            }
            captureCount += 1
        }

        patientRepository.pruneHandler = { _ in
            didPrune = true
        }

        mqttService.publishWithResultHandler = { _, _, _, _, _ in
            XCTFail("Should not be called")
        }

        patientRepository.updateIsSyncedHandler = { _, _ in
                .mock(id: captureCount)
        }

        testSubject.startSync()

        wait(for: [exp0], timeout: 2)
        XCTAssertEqual(capturedDiff, 50)

        wait(for: [exp1], timeout: 2)
        wait(for: [exp2], timeout: 2)
        wait(for: [exp3], timeout: 2)
        XCTAssertEqual(captureCount, 3)
        XCTAssertEqual(capturedTransmitter?.topic, "data/?/UNKNOWN/patient")
    }

    func testConnection() {
        let notificationName = NetworkMonitor.connectionNote

        let exp0 = expectation(description: "testStartSync_viaMQTT fetch-non-synced")
        exp0.expectedFulfillmentCount = 2
        var capturedDiff: Int?
        var didPrune = false
        patientRepository.fetchNonSyncedHandler = { diff in
            Task { @MainActor in exp0.fulfill() }
            capturedDiff = diff
            return didPrune ? [] : [.mock(id: 0), .mock(id: 1), .mock(id: 2)]
        }
        networkMonitor.isConnected = true
        mqttService.status = .connected
        userDefaults.turnProtocol = .Q2
        userDefaults.complianceAngle = .angle20

        mqttService.executeOnConnectionHandler = { _ in
            XCTFail("Should not be called")
        }

        nodeManager.transmitHandler = { _, _ in
            XCTFail("Should not be called")
        }

        patientRepository.pruneHandler = { _ in
            didPrune = true
        }

        var capturedTopic: String?
        let exp1 = expectation(description: "testStartSync_viaMQTT publishedWithResultHandler - 1")
        let exp2 = expectation(description: "testStartSync_viaMQTT publishedWithResultHandler - 2")
        let exp3 = expectation(description: "testStartSync_viaMQTT publishedWithResultHandler - 3")
        var captureCount = 0
        mqttService.publishWithResultHandler = { _, topicString, _, _, result in
            capturedTopic = topicString
            if captureCount == 0 {
                exp1.fulfill()
                result?(.success("yay 0"))
            } else if captureCount == 1 {
                exp2.fulfill()
                result?(.success("yay 1"))
            } else if captureCount == 2 {
                exp3.fulfill()
                result?(.success("yay 2"))
            } else {
                XCTFail("Should not be called \(captureCount + 1) times")
                result?(.failure(SyncManagerTests.Error.test))
            }
            captureCount += 1
        }

        patientRepository.updateIsSyncedHandler = { _, _ in
                .mock(id: captureCount)
        }

        rawNotifactionCenter.post(name: notificationName, object: nil)

        wait(for: [exp0], timeout: 2)
        XCTAssertEqual(capturedDiff, 50)

        wait(for: [exp1], timeout: 2)
        XCTAssertEqual(capturedTopic, "data/?/UNKNOWN/patient")
        wait(for: [exp2], timeout: 2)
        XCTAssertEqual(capturedTopic, "data/?/UNKNOWN/patient")
        wait(for: [exp3], timeout: 2)
        XCTAssertEqual(capturedTopic, "data/?/UNKNOWN/patient")
    }
}

private extension ALTPatient {
    static func mock(id: Int) -> ALTPatient {
        ALTPatient(
            hospitalRoomBedId: "roomBed \(id)",
            heightIn: 50,
            weightLbs: 50,
            hasPaceMaker: false,
            hasSternumSkinBroken: false,
            sex: id % 2 == 0 ? .female : .male,
            bmi: 10,
            props: "\(id)",
            id: "\(id)"
        )
    }
}
