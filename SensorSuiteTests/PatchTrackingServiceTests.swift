//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
@testable import SensorSuite_BMM
import XCTest

final class PatchTrackingServiceTests: XCTestCase {
    var keychain: MockKeychain!
    var provisioningAPIService: MockProvisioningAPIService!
    var patientManager: MockPatientManager!
    var userDefaults: MockUserDefaultsService!
    var notificationCenter: NotificationCenter = .init()
    var notificationCenterService: NotificationCenterService!
    var testSubject: PatchTrackingService!
    var container: Container!

    override func setUp() {
        container = .init()
        container.resetAll()

        keychain = MockKeychain()
        provisioningAPIService = MockProvisioningAPIService()
        patientManager = MockPatientManager()
        userDefaults = MockUserDefaultsService()
        notificationCenterService = NotificationCenterService(notificationCenter: notificationCenter)

        container.keychain.register { self.keychain }
        container.provisioningAPIService.register { self.provisioningAPIService }
        container.patientManager.register { self.patientManager }
        container.userDefaults.register { self.userDefaults }
        container.notificationCenter.register { self.notificationCenterService }

        testSubject = PatchTrackingService(container: container)
    }

    override func tearDown() {
        testSubject = nil
        notificationCenterService = nil
        userDefaults = nil
        patientManager = nil
        provisioningAPIService = nil
        keychain = nil
    }

    func testPatchUsed() {
        // GIVEN the services are configured with these 4 parameters:
        userDefaults.unsyncedPatchCount = 1
        patientManager.patientLocation = .mock(facilityId: "Facility1")
        patientManager.currentPatient = .mock(altID: "testAltPatient1")
        keychain.accessToken = "testToken1"

        // AND GIVEN the provisioning API service handler is configured to store input values
        let exp = XCTestExpectation(description: #function)
        var facilityID: String?
        var patientID: String?
        var patchCount: Int?
        var token: String?

        provisioningAPIService.addOnePatchHandler = { facilityId, patientId, patchCt, tkn in
            facilityID = facilityId
            patientID = patientId
            patchCount = patchCt
            token = tkn
            exp.fulfill()
            return [:]
        }

        // WHEN the `patchUsed()` method is called
        testSubject.patchUsed()

        wait(for: [exp])
        // THEN we expect the following results to be sent to the `addOnePatch` endpoint
        XCTAssertEqual(facilityID, "Facility1")
        XCTAssertEqual(patientID, "testAltPatient1")
        XCTAssertEqual(patchCount, 2)
        XCTAssertEqual(token, "testToken1")
        // AND the unsynced patch count to be reset to zero
        XCTAssertEqual(userDefaults.unsyncedPatchCount, 0)
    }

    func testConnected() {
        // GIVEN the services are configured with these 4 parameters:
        userDefaults.unsyncedPatchCount = 3
        patientManager.patientLocation = .mock(facilityId: "Facility2")
        patientManager.currentPatient = .mock(altID: "testAltPatient2")
        keychain.accessToken = "testToken2"

        // AND GIVEN the provisioning API service handler is configured to store input values
        let exp = XCTestExpectation(description: #function)
        var facilityID: String?
        var patientID: String?
        var patchCount: Int?
        var token: String?

        provisioningAPIService.addOnePatchHandler = { facilityId, patientId, patchCt, tkn in
            facilityID = facilityId
            patientID = patientId
            patchCount = patchCt
            token = tkn
            exp.fulfill()
            return [:]
        }

        // WHEN the `patchUsed()` method is called
        notificationCenterService.post(name: NetworkMonitor.connectionNote, object: nil)

        wait(for: [exp])
        // THEN we expect the following results to be sent to the `addOnePatch` endpoint
        XCTAssertEqual(facilityID, "Facility2")
        XCTAssertEqual(patientID, "testAltPatient2")
        XCTAssertEqual(patchCount, 3)
        XCTAssertEqual(token, "testToken2")
        // AND the unsynced patch count to be reset to zero
        XCTAssertEqual(userDefaults.unsyncedPatchCount, 0)
    }
    
    func testPatchUsed_whenMissingPrerequisites_doesNotSync() {
        // GIVEN - missing facility, patient, or token
        userDefaults.unsyncedPatchCount = 0
        patientManager.patientLocation = nil
        patientManager.currentPatient = nil
        keychain.accessToken = nil

        let inverted = XCTestExpectation(description: "addOnePatch should not be called when prerequisites are missing")
        inverted.isInverted = true
        provisioningAPIService.addOnePatchHandler = { _, _, _, _ in
            inverted.fulfill()
            return [:]
        }

        // WHEN - patchUsed is called
        testSubject.patchUsed()

        // THEN - count is incremented locally but no sync occurs
        wait(for: [inverted], timeout: 0.5)
        XCTAssertEqual(userDefaults.unsyncedPatchCount, 1)
    }

    func testConnectionNote_whenNoUnsyncedCount_doesNothing() {
        // GIVEN - there are no unsynced patches
        userDefaults.unsyncedPatchCount = 0
        let inverted = XCTestExpectation(description: "addOnePatch should not be called when count is zero")
        inverted.isInverted = true
        provisioningAPIService.addOnePatchHandler = { _, _, _, _ in
            inverted.fulfill()
            return [:]
        }

        // WHEN - a connection notification is posted
        notificationCenterService.post(name: NetworkMonitor.connectionNote, object: nil)

        // THEN - no sync occurs
        wait(for: [inverted], timeout: 0.5)
        XCTAssertEqual(userDefaults.unsyncedPatchCount, 0)
    }

    func testPatchUsed_whenAPIFails_retriesOnReconnect() {
        // GIVEN - unsynced count and valid prerequisites
        userDefaults.unsyncedPatchCount = 1
        patientManager.patientLocation = .mock(facilityId: "FacilityX")
        patientManager.currentPatient = .mock(altID: "altX")
        keychain.accessToken = "tokenX"

        let firstCall = XCTestExpectation(description: "first addOnePatch call (failure)")
        let secondCall = XCTestExpectation(description: "second addOnePatch call (success)")
        var callCount = 0
        provisioningAPIService.addOnePatchHandler = { facilityId, patientId, patchCt, token in
            callCount += 1
            if callCount == 1 {
                // First attempt fails
                firstCall.fulfill()
                throw NSError(domain: "test", code: -1)
            } else {
                // Second attempt succeeds
                XCTAssertEqual(facilityId, "FacilityX")
                XCTAssertEqual(patientId, "altX")
                XCTAssertEqual(token, "tokenX")
                // Patch count should remain the same as after the initial increment
                XCTAssertEqual(patchCt, 2)
                secondCall.fulfill()
                return [:]
            }
        }

        // WHEN - patchUsed is called (first attempt fails and leaves count unchanged)
        testSubject.patchUsed()
        wait(for: [firstCall], timeout: 2.0)
        XCTAssertEqual(userDefaults.unsyncedPatchCount, 2)

        // WHEN - connection is restored and a connection note is posted (should retry)
        notificationCenterService.post(name: NetworkMonitor.connectionNote, object: nil)

        // THEN - second attempt succeeds and resets the count
        wait(for: [secondCall], timeout: 2.0)
        XCTAssertEqual(userDefaults.unsyncedPatchCount, 0)
    }
}

// MARK: - Test Fixtures
private extension PatientLocation {
    static func mock(facilityId: String) -> PatientLocation {
        PatientLocation(
            unit: .mock(facilityId: facilityId),
            roomBed: .mock
        )
    }
}

private extension HospitalUnit {
    static func mock(facilityId: String) -> HospitalUnit {
        HospitalUnit(
            id: "testUnit",
            facilityId: facilityId,
            departmentId: "Dept1",
            name: "Unit1",
            status: "great",
            lastModified: .twenty25,
            lastModifiedBy: "null",
            serverLastModified: .twenty25
        )
    }
}

private extension HospitalRoomBed {
    static var mock: HospitalRoomBed {
        HospitalRoomBed(
            id: "testRoom",
            facilityUnitId: "testUnit",
            roomBedNumber: "Bed34",
            status: "great",
            lastModified: .twenty25,
            lastModifiedBy: "null",
            serverLastModified: .twenty25
        )
    }
}

private extension ALTPatient {
    static func mock(altID: String) -> ALTPatient {
        var patient = ALTPatient(
            hospitalRoomBedId: "testRoom",
            heightIn: 100,
            weightLbs: 100,
            hasPaceMaker: false,
            hasSternumSkinBroken: false,
            sex: .noAnswer,
            bmi: 1,
            props: "null",
            id: "testPatient"
        )
        patient.altPatientId = altID
        return patient
    }
}
