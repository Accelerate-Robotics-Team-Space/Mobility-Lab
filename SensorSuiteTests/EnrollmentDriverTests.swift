//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
@testable import SensorSuite_BMM
import XCTest

final class EnrollmentDriverTests: XCTestCase {
    enum EnrollmentTestError: Error, LocalizedError {
        case mock

        var errorDescription: String? {
            "Mock Error"
        }
    }

    private var container: Container!
    private var keychain: MockKeychain!
    private var userDefaults: MockUserDefaultsService!
    private var securityService: MockSecurityService!
    private var provisioningAPIService: MockProvisioningAPIService!
    private var mqttService: MockMQTTService!
    private var hospitalRoomBedRepository: MockHospitalRoomBedRepository!
    private var hospitalUnitRepository: MockHospitalUnitRepository!
    var testSubject: EnrollmentDriver!

    override func setUp() {
        container = .init()
        container.resetAll()

        keychain = MockKeychain()
        userDefaults = MockUserDefaultsService()
        securityService = MockSecurityService()
        provisioningAPIService = MockProvisioningAPIService()
        mqttService = MockMQTTService()
        hospitalUnitRepository = MockHospitalUnitRepository()
        hospitalRoomBedRepository = MockHospitalRoomBedRepository()
        
        container.keychain.register { self.keychain }
        container.userDefaults.register { self.userDefaults }
        container.securityService.register { self.securityService }
        container.provisioningAPIService.register { self.provisioningAPIService }
        container.mqttService.register { self.mqttService }
        container.hospitalUnitRepository.register { self.hospitalUnitRepository }
        container.hospitalRoomBedRepository.register { self.hospitalRoomBedRepository }

        testSubject = EnrollmentDriver(container: container)
    }

    override func tearDown() {
        testSubject = nil
        hospitalRoomBedRepository = nil
        hospitalUnitRepository = nil
        mqttService = nil
        provisioningAPIService = nil
        securityService = nil
        userDefaults = nil
        keychain = nil
        container = nil
    }

    func testScanHandler_success() {
        userDefaults.defaultingBaseStationFromApple = "base-station-id"

        let exp0 = expectation(description: "testScanHandler_success - dismiss")
        var dismissObserverCalled = false
        testSubject.dismissObserver {
            dismissObserverCalled = true
            exp0.fulfill()
        }

        let exp1 = expectation(description: "testScanHandler_success - validate token")
        var capturedCode: String?
        securityService.validateTokenHandler = { code, result in
            capturedCode = code
            exp1.fulfill()
            result(.success(("facility-1", "host-123")))
        }

        let exp2 = expectation(description: "testScanHandler_success - update device id")
        var deviceIdWasUpdated = false
        securityService.updateDeviceIdHandler = {
            deviceIdWasUpdated = true
            exp2.fulfill()
        }

        let exp3 = expectation(description: "testScanHandler_success - API register station")
        var registeredToBackend = false
        var capturedFacilityID: String?
        provisioningAPIService.registerBaseStationPublisherHandler = { facilityID in
            registeredToBackend = true
            capturedFacilityID = facilityID
            exp3.fulfill()
            return Just(DeviceRegistration.mock())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }

        let exp4 = expectation(description: "testScanHandler_success - sync unit to DB")
        var unitsRegistered = 0
        hospitalUnitRepository.syncSaveToDBHandler = { _, _, result in
            unitsRegistered += 1
            exp4.fulfill()
            result?(.success(()))
        }

        let exp5 = expectation(description: "testScanHandler_success - sync room to DB")
        exp5.expectedFulfillmentCount = 2
        var roomsRegistered = 0
        hospitalRoomBedRepository.syncSaveToDBHandler = { _, _, result in
            roomsRegistered += 1
            exp5.fulfill()
            result?(.success(()))
        }

        let exp6 = expectation(description: "testScanHandler_success - security - register device")
        var deviceWasRegistered = false
        securityService.registerDeviceHandler = { _, _, result in
            deviceWasRegistered = true
            exp6.fulfill()
            result(.success(()))
        }

        let exp7 = expectation(description: "testScanHandler_success - restart MQTT")
        var mqttWasRestarted = false
        mqttService.restartMQTTServiceHandler = {
            mqttWasRestarted = true
            exp7.fulfill()
        }

        testSubject.scanHandler(result: .success("code456"))

        wait(for: [exp0, exp1, exp2, exp3, exp4, exp5, exp6, exp7], timeout: 3)

        XCTAssertTrue(mqttWasRestarted)
        XCTAssertTrue(deviceWasRegistered)
        XCTAssertTrue(registeredToBackend)
        XCTAssertTrue(deviceIdWasUpdated)
        XCTAssertTrue(dismissObserverCalled)
        XCTAssertEqual(capturedCode, "code456")
        XCTAssertEqual(capturedFacilityID, "base-station-id")
        XCTAssertEqual(roomsRegistered, 2)
        XCTAssertEqual(unitsRegistered, 1)
        XCTAssertTrue(testSubject.deviceValidatedAndRegistered ?? false)
        XCTAssertFalse(testSubject.showAlert)
        XCTAssertEqual(keychain.accessToken, "code456")
        XCTAssertEqual(userDefaults.host, "host-123")
        let (title, message) = testSubject.alertInfo
        XCTAssertEqual(title, "None")
        XCTAssertEqual(message, "Unknown")
    }

    func testScanHandler_invalidToken() {
        userDefaults.defaultingBaseStationFromApple = "base-station-id"

        var dismissObserverCalled = false
        testSubject.dismissObserver {
            dismissObserverCalled = true
        }

        let exp1 = expectation(description: "testScanHandler_invalidToken - validate token")
        var capturedCode: String?
        securityService.validateTokenHandler = { code, result in
            capturedCode = code
            exp1.fulfill()
            result(.failure(EnrollmentTestError.mock))
        }

        var deviceIdWasUpdated = false
        securityService.updateDeviceIdHandler = {
            deviceIdWasUpdated = true
        }

        var capturedFacilityID: String?
        provisioningAPIService.registerBaseStationPublisherHandler = { facilityID in
            capturedFacilityID = facilityID
            return Just(DeviceRegistration.mock())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        var unitsRegistered = 0
        hospitalUnitRepository.syncSaveToDBHandler = { _, _, result in
            unitsRegistered += 1
            result?(.success(()))
        }

        var roomsRegistered = 0
        hospitalRoomBedRepository.syncSaveToDBHandler = { _, _, result in
            roomsRegistered += 1
            result?(.success(()))
        }

        var deviceWasRegistered = false
        securityService.registerDeviceHandler = { _, _, result in
            deviceWasRegistered = true
            result(.success(()))
        }

        var mqttWasRestarted = false
        mqttService.restartMQTTServiceHandler = {
            mqttWasRestarted = true
        }

        testSubject.scanHandler(result: .success("code456"))

        wait(for: [exp1], timeout: 1)

        XCTAssertFalse(mqttWasRestarted)
        XCTAssertFalse(deviceWasRegistered)
        XCTAssertFalse(deviceIdWasUpdated)
        XCTAssertFalse(dismissObserverCalled)
        XCTAssertEqual(capturedCode, "code456")
        XCTAssertNil(capturedFacilityID)
        XCTAssertEqual(roomsRegistered, 0)
        XCTAssertEqual(unitsRegistered, 0)
        XCTAssertNil(testSubject.deviceValidatedAndRegistered)
        XCTAssertTrue(testSubject.showAlert)
        XCTAssertEqual(keychain.accessToken, "code456")
        XCTAssertEqual(userDefaults.host, "")
        let (title, message) = testSubject.alertInfo
        XCTAssertEqual(title, "Certificate Error")
        XCTAssertEqual(message, "Mock Error")
    }

    func testScanHandler_apiFailure() {
        userDefaults.defaultingBaseStationFromApple = "base-station-id"

        var dismissObserverCalled = false
        testSubject.dismissObserver {
            dismissObserverCalled = true
        }

        let exp1 = expectation(description: "testScanHandler_apiFailure - validate token")
        var capturedCode: String?
        securityService.validateTokenHandler = { code, result in
            capturedCode = code
            exp1.fulfill()
            result(.success(("facility-1", "host-123")))
        }

        var deviceIdWasUpdated = false
        securityService.updateDeviceIdHandler = {
            deviceIdWasUpdated = true
        }

        let exp3 = expectation(description: "testScanHandler_apiFailure - API register station")
        var capturedFacilityID: String?
        provisioningAPIService.registerBaseStationPublisherHandler = { facilityID in
            capturedFacilityID = facilityID
            exp3.fulfill()
            return Fail(error: EnrollmentTestError.mock)
                .eraseToAnyPublisher()
        }

        var unitsRegistered = 0
        hospitalUnitRepository.syncSaveToDBHandler = { _, _, result in
            unitsRegistered += 1
            result?(.success(()))
        }

        var roomsRegistered = 0
        hospitalRoomBedRepository.syncSaveToDBHandler = { _, _, result in
            roomsRegistered += 1
            result?(.success(()))
        }

        var deviceWasRegistered = false
        securityService.registerDeviceHandler = { _, _, result in
            deviceWasRegistered = true
            result(.success(()))
        }

        var mqttWasRestarted = false
        mqttService.restartMQTTServiceHandler = {
            mqttWasRestarted = true
        }

        testSubject.scanHandler(result: .success("code456"))

        wait(for: [exp1, exp3], timeout: 1)

        XCTAssertFalse(mqttWasRestarted)
        XCTAssertFalse(deviceWasRegistered)
        XCTAssertTrue(deviceIdWasUpdated)
        XCTAssertFalse(dismissObserverCalled)
        XCTAssertEqual(capturedCode, "code456")
        XCTAssertEqual(capturedFacilityID, "base-station-id")
        XCTAssertEqual(roomsRegistered, 0)
        XCTAssertEqual(unitsRegistered, 0)
        XCTAssertNil(testSubject.deviceValidatedAndRegistered)
        XCTAssertTrue(testSubject.showAlert)
        XCTAssertNil(keychain.accessToken)
        XCTAssertEqual(userDefaults.host, "host-123")
        let (title, message) = testSubject.alertInfo
        XCTAssertEqual(title, "Networking Error")
        XCTAssertEqual(message, "Mock Error")
    }

    func testScanHandler_securityFailure() {
        userDefaults.defaultingBaseStationFromApple = "base-station-id"

        var dismissObserverCalled = false
        testSubject.dismissObserver {
            dismissObserverCalled = true
        }

        let exp1 = expectation(description: "testScanHandler_securityFailure - validate token")
        var capturedCode: String?
        securityService.validateTokenHandler = { code, result in
            capturedCode = code
            exp1.fulfill()
            result(.success(("facility-1", "host-123")))
        }

        var deviceIdWasUpdated = false
        securityService.updateDeviceIdHandler = {
            deviceIdWasUpdated = true
        }

        let exp3 = expectation(description: "testScanHandler_securityFailure - API register station")
        var capturedFacilityID: String?
        provisioningAPIService.registerBaseStationPublisherHandler = { facilityID in
            capturedFacilityID = facilityID
            exp3.fulfill()
            return Just(DeviceRegistration.mock())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        var unitsRegistered = 0
        hospitalUnitRepository.syncSaveToDBHandler = { _, _, result in
            unitsRegistered += 1
            result?(.success(()))
        }

        var roomsRegistered = 0
        hospitalRoomBedRepository.syncSaveToDBHandler = { _, _, result in
            roomsRegistered += 1
            result?(.success(()))
        }

        let exp6 = expectation(description: "testScanHandler_securityFailure - security - register device")
        securityService.registerDeviceHandler = { _, _, result in
            exp6.fulfill()
            result(.failure(EnrollmentTestError.mock))
        }

        var mqttWasRestarted = false
        mqttService.restartMQTTServiceHandler = {
            mqttWasRestarted = true
        }

        testSubject.scanHandler(result: .success("code456"))

        let exp8 = expectation(description: "testScanHandler_securityFailure - deviceValidated Publisher")
        var cancellable: AnyCancellable?
        cancellable = testSubject.$deviceValidatedAndRegistered
            .dropFirst()
            .sink { _ in
                exp8.fulfill()
                cancellable?.cancel()
            }

        wait(for: [exp1, exp3, exp6, exp8], timeout: 1)

        XCTAssertFalse(mqttWasRestarted)
        XCTAssertTrue(deviceIdWasUpdated)
        XCTAssertTrue(dismissObserverCalled)
        XCTAssertEqual(capturedCode, "code456")
        XCTAssertEqual(capturedFacilityID, "base-station-id")
        XCTAssertEqual(roomsRegistered, 2)
        XCTAssertEqual(unitsRegistered, 1)
        XCTAssertFalse(testSubject.deviceValidatedAndRegistered ?? true)
        XCTAssertNil(keychain.accessToken)
        XCTAssertEqual(userDefaults.host, "host-123")
        XCTAssertFalse(testSubject.showAlert)
        let (title, message) = testSubject.alertInfo
        XCTAssertEqual(title, "None")
        XCTAssertEqual(message, "Unknown")
    }

    func testScanHandler_validationFailure() {
        userDefaults.defaultingBaseStationFromApple = "base-station-id"

        var dismissObserverCalled = false
        testSubject.dismissObserver {
            dismissObserverCalled = true
        }

        let exp1 = expectation(description: "testScanHandler_validationFailure - validate token")
        var capturedCode: String?
        securityService.validateTokenHandler = { code, result in
            capturedCode = code
            exp1.fulfill()
            result(.success(("facility-1", "host-123")))
        }

        var deviceIdWasUpdated = false
        securityService.updateDeviceIdHandler = {
            deviceIdWasUpdated = true
        }

        let exp3 = expectation(description: "testScanHandler_validationFailure - API register station")
        var capturedFacilityID: String?
        provisioningAPIService.registerBaseStationPublisherHandler = { facilityID in
            capturedFacilityID = facilityID
            exp3.fulfill()
            return Just(DeviceRegistration.invalid())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        var unitsRegistered = 0
        hospitalUnitRepository.syncSaveToDBHandler = { _, _, result in
            unitsRegistered += 1
            result?(.success(()))
        }

        var roomsRegistered = 0
        hospitalRoomBedRepository.syncSaveToDBHandler = { _, _, result in
            roomsRegistered += 1
            result?(.success(()))
        }

        securityService.registerDeviceHandler = { _, _, result in
            result(.failure(EnrollmentTestError.mock))
        }

        var mqttWasRestarted = false
        mqttService.restartMQTTServiceHandler = {
            mqttWasRestarted = true
        }

        testSubject.scanHandler(result: .success("code456"))

        let exp8 = expectation(description: "testScanHandler_validationFailure - deviceValidated Publisher")
        var cancellable: AnyCancellable?
        cancellable = testSubject.$deviceValidatedAndRegistered
            .dropFirst()
            .sink { _ in
                exp8.fulfill()
                cancellable?.cancel()
            }

        wait(for: [exp1, exp3, exp8], timeout: 1)

        XCTAssertFalse(mqttWasRestarted)
        XCTAssertTrue(deviceIdWasUpdated)
        XCTAssertTrue(dismissObserverCalled)
        XCTAssertEqual(capturedCode, "code456")
        XCTAssertEqual(capturedFacilityID, "base-station-id")
        XCTAssertEqual(roomsRegistered, 0)
        XCTAssertEqual(unitsRegistered, 0)
        XCTAssertFalse(testSubject.deviceValidatedAndRegistered ?? true)
        XCTAssertEqual(keychain.accessToken, "code456")
        XCTAssertEqual(userDefaults.host, "host-123")
        XCTAssertTrue(testSubject.showAlert)
        let (title, message) = testSubject.alertInfo
        XCTAssertEqual(title, "Found Malformed Data")
        XCTAssertEqual(
            message,
            """
            Hospital units where found with no rooms, please contact your \
            administrator to ensure that all Hospital Units have at least a single room
            """
        )
    }

    func testScanHandler_badInput() {
        testSubject.scanHandler(result: .failure(.badInput))
        XCTAssertTrue(testSubject.showAlert)
        let (title, message) = testSubject.alertInfo
        XCTAssertEqual(title, "QR Scanner Error")
        XCTAssertEqual(message, "Bad Scanning Input")
    }

    func testScanHandler_badOutput() {
        testSubject.scanHandler(result: .failure(.badOutput))
        XCTAssertTrue(testSubject.showAlert)
        let (title, message) = testSubject.alertInfo
        XCTAssertEqual(title, "QR Scanner Error")
        XCTAssertEqual(message, "Bad Scanning Output")
    }
}

private extension DeviceRegistration {
    static func mock(
        id: String = "0",
        intCert: String = "intermediate-certificate",
        cert: String = "certificate"
    ) -> DeviceRegistration {
        DeviceRegistration(
            baseStationId: id,
            intermediateCertificate: intCert,
            certificate: cert,
            facilityName: "facility-1",
            units: [.mock(id: "0")],
            roomBeds: [
                .mock(id: "0", unit: "0"),
                .mock(id: "1", unit: "0"),
            ]
        )
    }

    static func invalid(
        id: String = "0",
        intCert: String = "intermediate-certificate",
        cert: String = "certificate"
    ) -> DeviceRegistration {
        DeviceRegistration(
            baseStationId: id,
            intermediateCertificate: intCert,
            certificate: cert,
            facilityName: "facility-1",
            units: [.mock(id: "0")],
            roomBeds: [
                .mock(id: "0", unit: "3"),
                .mock(id: "1", unit: "5"),
            ]
        )
    }
}

private extension HospitalUnit {
    static func mock(id: String = "0") -> HospitalUnit {
        HospitalUnit(
            id: id,
            facilityId: "facility-1",
            departmentId: "dept0",
            name: id,
            status: "great",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }
}

private extension HospitalRoomBed {
    static func mock(id: String = "0", unit: String = "0") -> HospitalRoomBed {
        HospitalRoomBed(
            id: id,
            facilityUnitId: unit,
            roomBedNumber: id,
            status: "beautiful",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }
}
