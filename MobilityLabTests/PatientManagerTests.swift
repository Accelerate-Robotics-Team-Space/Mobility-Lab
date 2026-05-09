//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
@testable import MobilityLab_BMM
import XCTest

final class PatientManagerTests: XCTestCase {
    enum TestError: Error {
        case test
    }

    private var container: Container!
    private var builder: PatientBuilder!
    private var activityLogRepository: MockActivityLogRepository!
    private var hospitalUnitRepository: MockHospitalUnitRepository!
    private var mqttService: MockMQTTService!
    private var networkMonitor: MockNetworkMonitor!
    private var nodeManager: MockNodeManager!
    private var rawNotificationCenter: NotificationCenter!
    private var notificationCenter: NotificationCenterService!
    private var patientRepository: MockPatientRepository!
    private var provisioningAPIService: MockProvisioningAPIService!
    private var securityService: MockSecurityService!
    private var sessionRepository: MockSessionRepository!
    private var userDefaults: MockUserDefaultsService!
    private var syncManager: MockSyncManager!
    private var delegate: PatientTestDelegate!

    private var testSubject: PatientManager!

    override func setUp() {
        super.setUp()
        container = .init()
        container.resetAll()

        activityLogRepository = MockActivityLogRepository()
        hospitalUnitRepository = MockHospitalUnitRepository()
        mqttService = MockMQTTService()
        networkMonitor = MockNetworkMonitor()
        nodeManager = MockNodeManager()
        rawNotificationCenter = NotificationCenter()
        notificationCenter = NotificationCenterService(notificationCenter: rawNotificationCenter)
        patientRepository = MockPatientRepository()
        provisioningAPIService = MockProvisioningAPIService()
        securityService = MockSecurityService()
        sessionRepository = MockSessionRepository()
        userDefaults = MockUserDefaultsService()
        syncManager = MockSyncManager()
        delegate = PatientTestDelegate()

        hospitalUnitRepository.getAllHandler = { HospitalUnitInfo.mocks }
        hospitalUnitRepository.updateHandler = { _ in (units: .init(), rooms: .init()) }
        mqttService.subscribeTopicsHandler = { }
        mqttService.executeOnConnectionHandler = { _ in }
        securityService.isDeviceRegisteredHandler = { true }
        networkMonitor.isConnected = true
        userDefaults.baseStationGuid = "elmo"
        userDefaults.facilityId = "bert"
        userDefaults.turnProtocol = .Q3
        userDefaults.complianceAngle = .angle25

        container.activityLogRepository.register { self.activityLogRepository }
        container.hospitalUnitRepository.register { self.hospitalUnitRepository }
        container.mqttService.register { self.mqttService }
        container.networkMonitor.register { self.networkMonitor }
        container.nodeManager.register { self.nodeManager }
        container.notificationCenter.register { self.notificationCenter }
        container.patientRepository.register { self.patientRepository }
        container.provisioningAPIService.register { self.provisioningAPIService }
        container.securityService.register { self.securityService }
        container.sessionRepository.register { self.sessionRepository }
        container.userDefaults.register { self.userDefaults }
        container.syncManager.register { self.syncManager }

        builder = PatientBuilder(container: container)
        testSubject = PatientManager(isPreview: false, container: container, builder: builder)
        testSubject.cachePatient = .mock()
        testSubject.delegate = delegate
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        activityLogRepository = nil
        builder = nil
        hospitalUnitRepository = nil
        rawNotificationCenter = nil
        mqttService = nil
        notificationCenter = nil
        nodeManager = nil
        networkMonitor = nil
        patientRepository = nil
        provisioningAPIService = nil
        securityService = nil
        sessionRepository = nil
        userDefaults = nil
        syncManager = nil
        container = nil
        delegate = nil
    }

    func testStartSession_success() {
        configureHandlers()
        let exp = expectation(description: #function)
        var startSessionSuccess = false
        testSubject.startSession(posToAvoid: [.right]) { startSessionResult in
            switch startSessionResult {
            case .success:
                startSessionSuccess = true
            case .failure(let error):
                XCTFail("Error Starting Session: \(error)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
        XCTAssertTrue(startSessionSuccess)
    }

    func testLoadSession_success() async {
        configureHandlers()
        let success = await testSubject.loadSession(sessionId: "fake")
        XCTAssertTrue(success)
    }

    @MainActor
    func testStopSession() {
        let exp0 = expectation(description: "stop session - sync cleanup")
        var syncManagerWasCleanedUp = false
        syncManager.cleanupHandler = { completion in
            syncManagerWasCleanedUp = true
            exp0.fulfill()
            completion?(.success(1))
        }
        let exp1 = expectation(description: "stop session - delete from DB")
        var allDeletedFromDB = false
        patientRepository.deleteAllFromDBHandler = { completion in
            allDeletedFromDB = true
            exp1.fulfill()
            completion?(.success(1))
        }

        testSubject.stopSession()

        wait(for: [exp0, exp1], timeout: 1)
        XCTAssertTrue(syncManagerWasCleanedUp)
        XCTAssertTrue(allDeletedFromDB)
        XCTAssertEqual(userDefaults.turnProtocol, .Q2)
        XCTAssertEqual(userDefaults.complianceAngle, .angle20)
        XCTAssertNil(testSubject.session)
    }

    func testUpdatePatientLocation_NilBuilder() async {
        configureHandlers()
        _ = await testSubject.loadSession(sessionId: "fake")
        XCTAssertNil(testSubject.builder)

        let exp0 = expectation(description: "testUpdatePatientLocation_NilBuilder - repository location update")
        patientRepository.updateLocationHandler = { patient, location in
            var mutable = patient
            mutable.update(roomBed: location.roomBed)
            exp0.fulfill()
            return mutable
        }

        let exp1 = expectation(description: "testUpdatePatientLocation_NilBuilder - location delegate")
        var delegateRoomBedID: String?
        delegate.locationHandler = { roomBedID in
            delegateRoomBedID = roomBedID
            exp1.fulfill()
        }

        testSubject.updatePatientLocation(hospitalUnit: .mock("0"), roomBed: .mock("blah", unit: "0"))

        await fulfillment(of: [exp0, exp1], timeout: 1)
        XCTAssertEqual(delegateRoomBedID, "blah")
    }

    func testUpdatePatientLocation_NonNilBuilder() async {
        configureHandlers()
        XCTAssertNotNil(testSubject.builder)

        let expectedRoom: HospitalRoomBed = .mock("blah", unit: "0")
        let expectedUnit: HospitalUnitInfo = .mock("0")
        testSubject.updatePatientLocation(hospitalUnit: expectedUnit, roomBed: expectedRoom)

        XCTAssertEqual(testSubject.builder?.hospitalRoomBed?.id, "blah")
        XCTAssertEqual(testSubject.builder?.hospitalUnit?.id, "0")
    }

    func testUpdatePatientProfile() {
        configureHandlers()
        XCTAssertNotNil(testSubject.builder)

        let profileUpdate: ALTPatient.ProfileUpdate = .init(
            height: 8,
            weight: 9,
            hasPaceMaker: true,
            hasSternumSkinBroken: true,
            sex: .male,
            bmi: 24,
            props: "some data",
            altPatientId: "alt-pat",
            sensorLocation: "in hospital"
        )

        testSubject.updatePatientProfile(id: "mock", update: profileUpdate)

        XCTAssertEqual(testSubject.builder?.heightIn, 8)
        XCTAssertEqual(testSubject.builder?.weightLbs, 9)
        XCTAssertTrue(testSubject.builder?.hasPaceMaker ?? false)
        XCTAssertTrue(testSubject.builder?.hasSternumSkinBroken ?? false)
        XCTAssertEqual(testSubject.builder?.bioSex, .male)
        XCTAssertEqual(testSubject.builder?.bioBmi, 24)
        XCTAssertEqual(testSubject.builder?.patientSensorLocation, "in hospital")
    }
}

private final class PatientTestDelegate: PatientMonitorDriverLocationDelegate {
    var locationHandler: ((String) -> Void)?

    func locationUpdated(hospitalRoomBedId: String) {
        locationHandler?(hospitalRoomBedId)
    }
}

private extension PatientManagerTests {
    func configureHandlers() {
        let roomBed: HospitalRoomBed = .mock("0", unit: "0")
        let roomBeds: [HospitalRoomBed] = [
            roomBed,
            .mock("1", unit: "0"),
            .mock("2", unit: "0"),
        ]
        builder.setHospital(unit: .mock("0", beds: roomBeds), roomBed: roomBed)
        builder.setProfile(
            height: 40,
            weight: 50,
            paceMaker: true,
            sternumSkinBroken: false,
            sex: .female,
            bmi: 10,
            sensorLocation: "in hospital"
        )

        patientRepository.saveToDBHandler = { patient, queue, completion in
            let updated = ALTPatient(
                hospitalRoomBedId: patient.hospitalRoomBedId,
                heightIn: patient.heightIn,
                weightLbs: patient.weightLbs,
                hasPaceMaker: patient.hasPaceMaker,
                hasSternumSkinBroken: patient.hasSternumSkinBroken,
                sex: patient.sex,
                bmi: patient.bmi,
                props: patient.props,
                id: "12345"
            )
            queue.async {
                completion?(.success(updated))
            }
        }
        patientRepository.loadIdCompletionFromDBHandler = { _, _, completion in
            completion?(.success(.mock()))
        }
        sessionRepository.getSessionByIDHandler = { _ in .mock() }
        sessionRepository.getSessionByPatientIDHandler = { _, _, _ in .mock() }
        sessionRepository.asyncSaveToDBHandler = { session in session }

        patientRepository.updatePropsHandler = { patient, props in
            var mutable = patient
            mutable.props = props
            return mutable
        }
        let data: [String: Any] = ["Smart": "Thing"]
        provisioningAPIService.addNewPatientHandler = { _ in ["data": data] }
        patientRepository.updateLocationHandler = { patient, location in
            var mutablePatient = patient
            mutablePatient.update(roomBed: location.roomBed)
            return mutablePatient
        }
        patientRepository.updateAltPatientIdHandler = { patient, altID in
            var mutablePatient = patient
            mutablePatient.altPatientId = altID
            return mutablePatient
        }
        hospitalUnitRepository.getAllHandler = { HospitalUnitInfo.mocks }
        patientRepository.updateProfileHandler = { _, _ in .mock() }
        activityLogRepository.withLastEndDateHandler = { .mock() }
    }
}

private extension ALTPatient {
    static func mock(id: String = "test-id", roomBed: String = "foo", withRoomBed: Bool = true) -> ALTPatient {
        var patient = ALTPatient(
            hospitalRoomBedId: roomBed,
            heightIn: 200,
            weightLbs: 100,
            hasPaceMaker: false,
            hasSternumSkinBroken: false,
            sex: .female,
            bmi: 1,
            props: "{\"avoid\":\"L\"}",
            id: id
        )
        if withRoomBed {
            patient.update(roomBed: .mock(roomBed, unit: "0"))
        }
        return patient
    }
}

private extension TurnTrackerInfo {
    static func mock() -> TurnTrackerInfo {
        TurnTrackerInfo(
            endDate: nil,
            positionalFlagCategory: .supine,
            remainingTime: 0,
            delegate: nil
        )
    }
}

private extension ALTSession {
    static func mock(id: String = "fake-session-id", patient: ALTPatient? = .mock()) -> ALTSession {
        var session = ALTSession(
            patientId: patient?.id ?? "patient-id",
            turningProtocol: .superShort,
            positionsToAvoid: .walking,
            hasEnded: false,
            id: id
        )
        session.patient = patient
        return session
    }
}

private extension UnitRoomModel {
    static func mock() -> UnitRoomModel {
        UnitRoomModel(
            facilityName: "facility1",
            facilityId: UUID(),
            units: [.mock("0"), .mock("1")],
            roomBeds: [
                .mock("fum", unit: "0"),
                .mock("foo", unit: "0"),
                .mock("bar", unit: "1"),
                .mock("baz", unit: "1"),
            ]
        )
    }
}

private extension HospitalUnit {
    static func mock(_ id: String) -> HospitalUnit {
        HospitalUnit(
            id: id,
            facilityId: "facility1",
            departmentId: "dept0",
            name: "\(id)",
            status: "grand",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }
}

private extension HospitalRoomBed {
    static func mock(_ id: String, unit: String) -> HospitalRoomBed {
        HospitalRoomBed(
            id: id,
            facilityUnitId: unit,
            roomBedNumber: id,
            status: "fantastic",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }
}

private extension HospitalUnitInfo {
    static func mock(_ id: String, beds: [HospitalRoomBed] = [.mock("0", unit: "foo")]) -> HospitalUnitInfo {
        HospitalUnitInfo(
            id: id,
            facilityId: "facility1",
            departmentId: "dept0",
            name: "\(id)",
            status: "grand",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25,
            roomBeds: beds
        )
    }

    static var mocks: [HospitalUnitInfo] {
        [
            .mock("0", beds: [.mock("fum", unit: "0"), .mock("foo", unit: "0")]),
            .mock("1", beds: [.mock("bar", unit: "1"), .mock("buz", unit: "1")]),
        ]
    }
}

private extension ALTActivityLog {
    static func mock(id: Int64 = 0) -> ALTActivityLog {
        ALTActivityLog(
            patientID: "test-id",
            sessionID: "fake-session-id",
            actualPosition: .left,
            startingTarget: .left,
            startingTimeRemaining: 40,
            endingTimeRemaining: 50,
            bmmMonitoringState: "lovely",
            bmmPauseReason: "none",
            isWrongPosition: false,
            hospitalRoomBedID: "0",
            mqttTopicStr: "x/y/z/topic",
            updateID: "upity",
            headOfBedAngle: 20,
            turnAngle: 25,
            endingTargetPosition: "CEO",
            id: id,
            isCurrent: true,
            isSynced: false
        )
    }
}
