//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
@testable import MobilityLab_BMM
import XCTest

final class PatientLandingDriverTests: XCTestCase {
    enum Error: Swift.Error {
        case test
    }

    private var container: Container!
    private var activityLogRepository: MockActivityLogRepository!
    private var patientRepository: MockPatientRepository!
    private var sessionRepository: MockSessionRepository!
    private var rawNotificationCenter: NotificationCenter!
    private var notificationCenter: NotificationCenterService!
    private var securityService: MockSecurityService!
    private var mqttService: MockMQTTService!
    private var userDefaults: MockUserDefaultsService!
    private var provisioningAPIService: MockProvisioningAPIService!
    private var patientManager: MockPatientManager!
    private var syncManager: MockSyncManager!
    private var testSubject: PatientLandingDriver!

    override func setUp() {
        super.setUp()
        container = .init()
        container.resetAll()

        activityLogRepository = MockActivityLogRepository()
        patientRepository = MockPatientRepository()
        sessionRepository = MockSessionRepository()
        rawNotificationCenter = NotificationCenter()
        notificationCenter = NotificationCenterService(notificationCenter: rawNotificationCenter)
        securityService = MockSecurityService()
        mqttService = MockMQTTService()
        userDefaults = MockUserDefaultsService()
        provisioningAPIService = MockProvisioningAPIService()
        patientManager = MockPatientManager()
        syncManager = MockSyncManager()

        securityService.isDeviceRegisteredHandler = { true }
        securityService.resetAllIsCurrentHandler = { }
        userDefaults.baseStationFromApple = "A Device"

        container.activityLogRepository.register { self.activityLogRepository }
        container.patientRepository.register { self.patientRepository }
        container.sessionRepository.register { self.sessionRepository }
        container.notificationCenter.register { self.notificationCenter }
        container.securityService.register { self.securityService }
        container.mqttService.register { self.mqttService }
        container.userDefaults.register { self.userDefaults }
        container.provisioningAPIService.register { self.provisioningAPIService }
        container.patientManager.register { self.patientManager }
        container.syncManager.register { self.syncManager }

        testSubject = PatientLandingDriver(container: container)
    }

    override func tearDown() {
        super.tearDown()

        testSubject = nil
        syncManager = nil
        patientManager = nil
        provisioningAPIService = nil
        userDefaults = nil
        mqttService = nil
        securityService = nil
        notificationCenter = nil
        rawNotificationCenter = nil
        sessionRepository = nil
        patientRepository = nil
        activityLogRepository = nil
    }

    func testBuildInfo() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        XCTAssertEqual(testSubject.buildInfo, "Version: \(version ?? "?") (\(build ?? "Automated")) | Unknown")
    }

    func testDeviceID() {
        userDefaults.baseStationFromApple = "A Device"
        XCTAssertEqual(testSubject.deviceID, "A Device")
    }

    func testUpdateRegistrationState_isRegistered() {
        securityService.isDeviceRegisteredHandler = { true }
        let exp = expectation(description: #function)
        var sessionStarted = false
        mqttService.startSessionHandler = {
            sessionStarted = true
            exp.fulfill()
        }

        testSubject.updateRegistrationState()
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(sessionStarted)
    }

    func testUpdateRegistrationState_isNotRegistered() {
        securityService.isDeviceRegisteredHandler = { false }
        mqttService.startSessionHandler = {
            XCTFail("Session should not be started")
        }

        testSubject.updateRegistrationState()
    }

    func testGetFacilityConfig_success() {
        userDefaults.facilityId = "facility one"
        let exp0 = expectation(description: "testGetFacilityConfig_success - Get Config Handler")
        var capturedFacility: String?
        provisioningAPIService.getConfigHandler = { facility in
            capturedFacility = facility
            exp0.fulfill()
            return Just(.mock()).setFailureType(to: Swift.Error.self).eraseToAnyPublisher()
        }

        let exp1 = expectation(description: "testGetFacilityConfig_success - Get Facility Config")
        var capturedSuccess: Bool?
        testSubject.getFacilityConfig { success in
            capturedSuccess = success
            exp1.fulfill()
        }

        wait(for: [exp0, exp1], timeout: 1)

        XCTAssertEqual(capturedFacility, "facility one")
        XCTAssertTrue(capturedSuccess ?? false)
        XCTAssertEqual(userDefaults.turnProtocol, .Q3)
        XCTAssertEqual(userDefaults.complianceAngle, .angle20)
        XCTAssertFalse(userDefaults.isComplianceEnabled)
        XCTAssertTrue(userDefaults.isTurnProtocolEnabled)
    }

    func testGetFacilityConfig_failure() {
        userDefaults.facilityId = "facility one"
        let exp0 = expectation(description: "testGetFacilityConfig_failure - Get Config Handler")
        var capturedFacility: String?
        provisioningAPIService.getConfigHandler = { facility in
            capturedFacility = facility
            exp0.fulfill()
            return Fail(error: PatientLandingDriverTests.Error.test).eraseToAnyPublisher()
        }

        let exp1 = expectation(description: "testGetFacilityConfig_failure - Get Facility Config")
        var capturedSuccess: Bool?
        testSubject.getFacilityConfig { success in
            capturedSuccess = success
            exp1.fulfill()
        }

        wait(for: [exp0, exp1], timeout: 1)

        XCTAssertEqual(capturedFacility, "facility one")
        XCTAssertFalse(capturedSuccess ?? true)
        XCTAssertNil(userDefaults.turnProtocol)
        XCTAssertNil(userDefaults.complianceAngle)
        XCTAssertFalse(userDefaults.isComplianceEnabled)
        XCTAssertFalse(userDefaults.isTurnProtocolEnabled)
    }

    func testGetLastSessionIfExists_sessionEnded() async {
        userDefaults.defaultingBaseStationFromApple = "Wu-Tang is forever"
        let expectedSession: ALTSession = .mock(id: "789", patientID: "XYZ", hasEnded: true)
        let exp0 = expectation(description: "testGetLastSessionIfExists_sessionEnded - get last session handler")
        sessionRepository.getLastSessionHandler = {
            exp0.fulfill()
            return expectedSession
        }

        patientManager.loadSessionHandler = { _ in
            XCTFail("'loadSession(sessionId:)' Should not be called")
            return false
        }

        let lastSession = await testSubject.getLastSessionIfExists()
        await fulfillment(of: [exp0], timeout: 1)
        XCTAssertNil(lastSession)
    }

    func testGetLastSessionIfExists_sessionNotEnded() async {
        userDefaults.defaultingBaseStationFromApple = "Wu-Tang is forever"
        let expectedSession: ALTSession = .mock(id: "789", patientID: "XYZ", hasEnded: false)
        sessionRepository.getLastSessionHandler = {
            expectedSession
        }

        let exp0 = expectation(description: "testGetLastSessionIfExists_sessionNotEnded - load session handler")
        exp0.expectedFulfillmentCount = 2
        var capturedSessionID: String?
        patientManager.loadSessionHandler = { sessionID in
            capturedSessionID = sessionID
            exp0.fulfill()
            return true
        }

        let lastSession = await testSubject.getLastSessionIfExists()

        await fulfillment(of: [exp0], timeout: 1)
        XCTAssertEqual(lastSession, expectedSession)
        XCTAssertEqual(capturedSessionID, "789")
    }

    func testCertificateRevoked() {
        securityService.isDeviceRegisteredHandler = { true }
        rawNotificationCenter.post(name: SecurityService.revokedNote, object: nil)

        XCTAssertTrue(testSubject.isRegistered)
    }
}

private extension FacilityConfig {
    static func mock(
        turnProtocol: TurnProtocol = .Q3,
        complianceAngle: ComplianceAngle = .angle20,
        enableCompliance: Bool? = false,
        enableTurnProtocol: Bool? = true
    ) -> FacilityConfig {
        FacilityConfig(
            complianceDegree: complianceAngle.intValue,
            turnProtocol: turnProtocol.rawValue,
            enableCompliance: enableCompliance,
            enableTurnProtocol: enableTurnProtocol
        )
    }
}

private extension ALTSession {
    static func mock(
        id: String?,
        patientID: String,
        hasEnded: Bool,
        turnProtocol: TurningProtocol = .q3Turn,
        posToAvoid: PositionalFlags = .trendelenburg
    ) -> ALTSession {
        ALTSession(
            patientId: patientID,
            turningProtocol: turnProtocol,
            positionsToAvoid: posToAvoid,
            hasEnded: hasEnded,
            id: id
        )
    }
}
