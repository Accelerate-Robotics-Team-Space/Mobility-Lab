//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
@testable import MobilityLab_BMM
import XCTest

final class ActivityLogServiceTests: XCTestCase {
    var testSubject: ActivityLogService!
    var activityLogRepository: MockActivityLogRepository!
    var mqttService: MockMQTTService!
    var patientManager: MockPatientManager!
    var userDefaults: MockUserDefaultsService!
    var rawNotificationCenter: NotificationCenter!
    var notificationCenter: NotificationCenterService!
    var rollCompliance: MockRollCompliance!
    var securityService: MockSecurityService!
    var container: Container!

    override func setUp() {
        super.setUp()
        container = .init()
        container.resetAll()
        activityLogRepository = MockActivityLogRepository()
        mqttService = MockMQTTService()
        patientManager = MockPatientManager()
        userDefaults = MockUserDefaultsService()
        rawNotificationCenter = NotificationCenter()
        notificationCenter = NotificationCenterService(notificationCenter: rawNotificationCenter)
        rollCompliance = MockRollCompliance()
        securityService = MockSecurityService()

        rollCompliance.targetRollHandler = { _ in 0 ... 100 }
        userDefaults.complianceAngle = .angle25
        securityService.isDeviceRegisteredHandler = { true }

        container.activityLogRepository.register { self.activityLogRepository }
        container.mqttService.register { self.mqttService }
        container.patientManager.register { self.patientManager }
        container.userDefaults.register { self.userDefaults }
        container.notificationCenter.register { self.notificationCenter }
        container.rollCompliance.register { self.rollCompliance }
        container.securityService.register { self.securityService }

        testSubject = ActivityLogService(container: container)
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        notificationCenter = nil
        userDefaults = nil
        patientManager = nil
        mqttService = nil
        activityLogRepository = nil
        container = nil
        rawNotificationCenter = nil
        rollCompliance = nil
        securityService = nil
    }

    func testSetup() {
        // GIVEN - a fresh service and a new session id
        let exp = expectation(description: "deleteAll called for new session")
        var deleteAllCallCount = 0
        activityLogRepository.deleteAllHandler = {
            deleteAllCallCount += 1
            exp.fulfill()
            return 0
        }

        // WHEN - setup is invoked with a new session id
        testSubject.setup(with: "session-1")

        // THEN - deleteAll should be called once asynchronously
        wait(for: [exp], timeout: 2.0)
        XCTAssertEqual(deleteAllCallCount, 1)
    }

    func testResume() {
        // GIVEN - a fresh service
        let exp = expectation(description: "endAllActivityLog called")
        var endAllCallCount = 0
        activityLogRepository.endAllActivityLogsHandler = {
            endAllCallCount += 1
            exp.fulfill()
        }

        // WHEN - resume is invoked
        testSubject.resume(with: "session-1")

        // THEN - endAllActivityLog should be called once asynchronously
        wait(for: [exp], timeout: 2.0)
        XCTAssertEqual(endAllCallCount, 1)
    }

    func testSyncActivities() {
        // GIVEN - unsynced activity logs and a connected MQTT service
        userDefaults.defaultingBaseStationFromApple = "Echo Base"
        let logs = Array(ALTActivityLog.mockData().prefix(2))

        let fetchExp = expectation(description: "fetchNonSynced called")
        activityLogRepository.fetchNonSyncedWithLimitHandler = { limit in
            XCTAssertEqual(limit, 1000) // default limit from getNotUploadedActivities
            fetchExp.fulfill()
            return logs
        }

        let publishExp = expectation(description: "publish called for each log")
        publishExp.expectedFulfillmentCount = logs.count

        let saveExp = expectation(description: "syncSaveToDB called for each log")
        saveExp.expectedFulfillmentCount = logs.count

        var savedIsSyncedValues: [Bool] = []
        activityLogRepository.syncSaveToDBHandler = { log, _, _ in
            savedIsSyncedValues.append(log.isSynced)
            saveExp.fulfill()
        }

        mqttService.publishWithResultHandler = { data, topic, isRetained, qos, result in
            XCTAssertFalse(data.isEmpty, "Published data should not be empty")
            XCTAssertFalse(isRetained)
            XCTAssertEqual(qos, .atLeastOnce)
            // Topic may be empty in mock data; just ensure it's a String
            _ = topic
            publishExp.fulfill()
            result?(.success("ok"))
        }

        let uploadExp = expectation(description: "uploadPatientInfo called once after publishing")
        var uploadCallCount = 0
        patientManager.uploadPatientInfoHandler = {
            uploadCallCount += 1
            uploadExp.fulfill()
        }

        // WHEN - the mqttService reports that it is connected and posts a status update
        mqttService.status = .connected
        rawNotificationCenter.post(name: MQTTService.statusNote, object: nil)

        // THEN - all logs are published, saved as synced, and patient info uploaded
        wait(for: [fetchExp, publishExp, saveExp, uploadExp], timeout: 3.0)
        XCTAssertEqual(savedIsSyncedValues.count, logs.count)
        XCTAssertTrue(savedIsSyncedValues.allSatisfy { $0 == true }, "All saved logs should be marked as synced on success")
        XCTAssertEqual(uploadCallCount, 1)
    }

    func testSetup_whenNilOrSameSession_doesNotDelete() {
        // GIVEN - a handler that would crash if called unexpectedly
        let inverted = expectation(description: "deleteAll should not be called")
        inverted.isInverted = true
        activityLogRepository.deleteAllHandler = {
            inverted.fulfill()
            return 0
        }

        // WHEN - setup is invoked with nil session id
        testSubject.setup(with: nil)
        // THEN - no delete should occur
        wait(for: [inverted], timeout: 0.5)

        // GIVEN - setup once with a valid id to establish current session
        let expFirst = expectation(description: "deleteAll called for first valid session")
        activityLogRepository.deleteAllHandler = {
            expFirst.fulfill()
            return 0
        }
        testSubject.setup(with: "session-A")
        wait(for: [expFirst], timeout: 1.5)

        // WHEN - setup is invoked again with the same id
        let invertedSecond = expectation(description: "deleteAll should not be called for same session")
        invertedSecond.isInverted = true
        activityLogRepository.deleteAllHandler = {
            invertedSecond.fulfill()
            return 0
        }
        testSubject.setup(with: "session-A")

        // THEN - no further delete should occur
        wait(for: [invertedSecond], timeout: 0.5)
    }

    func testSyncActivities_whenNotConnected_doesNothing() {
        // GIVEN - an inverted expectation for upload and publish
        let invertedUpload = expectation(description: "uploadPatientInfo should not be called")
        invertedUpload.isInverted = true
        patientManager.uploadPatientInfoHandler = {
            invertedUpload.fulfill()
        }

        let invertedPublish = expectation(description: "publish should not be called")
        invertedPublish.isInverted = true
        mqttService.publishWithResultHandler = { _, _, _, _, _ in
            invertedPublish.fulfill()
        }

        // WHEN - status is not connected and notification is posted
        mqttService.status = .disconnected
        rawNotificationCenter.post(name: MQTTService.statusNote, object: nil)

        // THEN - no sync should occur
        wait(for: [invertedUpload, invertedPublish], timeout: 0.5)
    }

    func testSyncActivities_publishFailure_marksLogsNotSynced() {
        // GIVEN - unsynced activity logs and publish failure
        userDefaults.defaultingBaseStationFromApple = "Echo Base"
        let logs = Array(ALTActivityLog.mockData().prefix(2))
        activityLogRepository.fetchNonSyncedWithLimitHandler = { _ in logs }

        let saveExp = expectation(description: "syncSaveToDB called for each log")
        saveExp.expectedFulfillmentCount = logs.count
        var savedIsSyncedValues: [Bool] = []
        activityLogRepository.syncSaveToDBHandler = { log, _, _ in
            savedIsSyncedValues.append(log.isSynced)
            saveExp.fulfill()
        }

        mqttService.publishWithResultHandler = { _, _, _, _, result in
            result?(.failure(NSError(domain: "test", code: -1)))
        }

        let uploadExp = expectation(description: "uploadPatientInfo called once after attempts")
        patientManager.uploadPatientInfoHandler = {
            uploadExp.fulfill()
        }

        // WHEN - connected and status update posted
        mqttService.status = .connected
        rawNotificationCenter.post(name: MQTTService.statusNote, object: nil)

        // THEN - logs should be saved with isSynced = false
        wait(for: [saveExp, uploadExp], timeout: 3.0)
        XCTAssertEqual(savedIsSyncedValues.count, logs.count)
        XCTAssertTrue(savedIsSyncedValues.allSatisfy { $0 == false }, "All saved logs should be marked as not synced on failure")
    }
}
