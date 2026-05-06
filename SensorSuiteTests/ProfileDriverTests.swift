//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
@testable import SensorSuite_BMM
import XCTest

final class ProfileDriverTests: XCTestCase {
    enum Error: Swift.Error {
        case test
    }

    private var container: Container!
    private var userDefaults: MockUserDefaultsService!
    private var provisioningAPIService: MockProvisioningAPIService!
    private var networkMonitor: MockNetworkMonitor!
    private var patientManager: MockPatientManager!
    private var patientMonitor: MockPatientMonitor!
    private var hospitalUnitRepository: MockHospitalUnitRepository!
    private var hospitalRoomBedRepository: MockHospitalRoomBedRepository!
    private var patientRepository: MockPatientRepository!

    private var testSubject: ProfileDriver!

    @MainActor
    override func setUp() {
        super.setUp()
        container = .init()
        container.resetAll()

        userDefaults = MockUserDefaultsService()
        provisioningAPIService = MockProvisioningAPIService()
        networkMonitor = MockNetworkMonitor()
        patientManager = MockPatientManager()
        patientMonitor = MockPatientMonitor()
        hospitalUnitRepository = MockHospitalUnitRepository()
        hospitalRoomBedRepository = MockHospitalRoomBedRepository()
        patientRepository = MockPatientRepository()

        container.userDefaults.register { self.userDefaults }
        container.provisioningAPIService.register { self.provisioningAPIService }
        container.networkMonitor.register { self.networkMonitor }
        container.patientManager.register { self.patientManager }
        container.hospitalUnitRepository.register { self.hospitalUnitRepository }
        container.hospitalRoomBedRepository.register { self.hospitalRoomBedRepository }
        container.patientRepository.register { self.patientRepository }

        hospitalUnitRepository.getAllHandler = { [] }
        hospitalUnitRepository.updateHandler = { _ in
            (units: .init(), rooms: .init())
        }
        provisioningAPIService.getUnitRoomsHandler = { _ in
            Just(.mock()).setFailureType(to: Swift.Error.self).eraseToAnyPublisher()
        }
        patientRepository.latestPatientHandler = { .mock() }

        userDefaults.baseStationGuid = "twenty nine"
        userDefaults.facilityId = "seventy eleventy"
        userDefaults.turnProtocol = .Q4
        userDefaults.complianceAngle = .angle25
        networkMonitor.isConnected = true

        testSubject = ProfileDriver(.mock(), container: container)
        testSubject.set(patientMonitor: patientMonitor)
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        userDefaults = nil
        provisioningAPIService = nil
        networkMonitor = nil
        patientManager = nil
        patientMonitor = nil
        container = nil
    }

    @MainActor
    func testStopSession() async throws {
        let exp0 = expectation(description: #function)
        var capturedModel: StartEndSessionModel?
        provisioningAPIService.endPatientSessionHandler = { model in
            capturedModel = model
            exp0.fulfill()
            return [:]
        }

        try await testSubject.stopSession()
        await fulfillment(of: [exp0], timeout: 1)
        XCTAssertTrue(testSubject.canShowEndReminder)
        XCTAssertNotNil(capturedModel)
        XCTAssertEqual(capturedModel?.baseStationId, "twenty nine")
        XCTAssertEqual(capturedModel?.facilityId, "seventy eleventy")
        XCTAssertEqual(capturedModel?.patientDetails.patientId, "patient1")
        XCTAssertEqual(capturedModel?.patientDetails.complianceDegree, 25)
        XCTAssertEqual(capturedModel?.patientDetails.turnProtocol, "Q4")
        XCTAssertEqual(capturedModel?.patientDetails.props, "contra")
    }

    @MainActor
    func testProcessEndMonitoring_syncLogs() {
        // GIVEN -
        let exp0 = expectation(description: "testProcessEndMonitoring - monitoring state")
        var capturedState: ProfileDriver.EndMonitoringState?
        var cancellable: AnyCancellable?
        var stateWasSetTo_endingInitiated = false
        cancellable = testSubject.$endMonitoringState
            .dropFirst()
            .sink { state in
                switch state {
                case .syncingLogs(let attempt):
                    if attempt == 0 {
                        return
                    }
                case .endingInitiated:
                    stateWasSetTo_endingInitiated = true
                    return
                default:
                    break
                }
                capturedState = state
                exp0.fulfill()
                cancellable?.cancel()
            }

        var stopTimersCalled = false
        var syncLogsCalled = false
        let exp1 = expectation(description: "testProcessEndMonitoring - stop timers")
        let exp2 = expectation(description: "testProcessEndMonitoring - sync logs")
        patientMonitor.stopTimersHandler = {
            stopTimersCalled = true
            exp1.fulfill()
        }
        patientMonitor.syncLogsHandler = {
            try? await Task.sleep(nanoseconds: 2_000)
            syncLogsCalled = true
            exp2.fulfill()
        }

        // WHEN - the state is set to sync logs
        testSubject.endMonitoringState = .syncingLogs(attempt: 0)

        wait(for: [exp0, exp1, exp2], timeout: 2)

        // THEN - We expect the following to
        XCTAssertTrue(stopTimersCalled)
        XCTAssertTrue(syncLogsCalled)
        XCTAssertTrue(stateWasSetTo_endingInitiated)
        XCTAssertEqual(capturedState, .backendEndMonitoring)
    }

    @MainActor
    func testProcessEndMonitoring_backendMonitoring() {
        // GIVEN -
        let exp0 = expectation(description: "testProcessEndMonitoring - backend monitoring")
        var capturedState: ProfileDriver.EndMonitoringState?
        var cancellable: AnyCancellable?
        cancellable = testSubject.$endMonitoringState
            .dropFirst()
            .sink { state in
                switch state {
                case .backendEndMonitoring:
                    return
                default:
                    break
                }
                capturedState = state
                exp0.fulfill()
                cancellable?.cancel()
            }

        let exp1 = expectation(description: "testProcessEndMonitoring - backend monitoring - end patient session")
        var capturedModel: StartEndSessionModel?
        provisioningAPIService.endPatientSessionHandler = { model in
            capturedModel = model
            exp1.fulfill()
            return [:]
        }

        // WHEN - the state is set to backend monitoring
        testSubject.endMonitoringState = .backendEndMonitoring

        wait(for: [exp0, exp1], timeout: 1)

        // THEN - We expect the following to
        XCTAssertTrue(patientMonitor.syncingLogs.isEmpty)
        XCTAssertTrue(testSubject.canShowEndReminder)
        XCTAssertEqual(capturedState, .done)
        XCTAssertNotNil(capturedModel)
        XCTAssertEqual(capturedModel?.baseStationId, "twenty nine")
        XCTAssertEqual(capturedModel?.facilityId, "seventy eleventy")
        XCTAssertEqual(capturedModel?.patientDetails.patientId, "patient1")
        XCTAssertEqual(capturedModel?.patientDetails.complianceDegree, 25)
        XCTAssertEqual(capturedModel?.patientDetails.turnProtocol, "Q4")
        XCTAssertEqual(capturedModel?.patientDetails.props, "contra")
    }

    @MainActor
    func testProcessEndMonitoring_done() {
        // GIVEN -
        let exp0 = expectation(description: "testProcessEndMonitoring - done - final state")
        var capturedState: ProfileDriver.EndMonitoringState?
        var cancellable: AnyCancellable?
        cancellable = testSubject.$endMonitoringState
            .dropFirst()
            .sink { state in
                switch state {
                case .done:
                    return
                default:
                    break
                }
                capturedState = state
                exp0.fulfill()
                cancellable?.cancel()
            }

        let exp1 = expectation(description: "testProcessEndMonitoring - done - end patient session")
        var patientMonitor_endSessionWasCalled = false
        patientMonitor.endSessionHandler = {
            patientMonitor_endSessionWasCalled = true
            exp1.fulfill()
        }

        let exp2 = expectation(description: "testProcessEndMonitoring - done - stop session")
        var patientManager_stopSessionWasCalled = false
        patientManager.stopSessionHandler = {
            patientManager_stopSessionWasCalled = true
            exp2.fulfill()
        }

        // WHEN - the state is set to backend monitoring
        testSubject.endMonitoringState = .done

        wait(for: [exp0, exp1, exp2], timeout: 10)

        // THEN - We expect the following to
        XCTAssertTrue(patientManager_stopSessionWasCalled)
        XCTAssertTrue(patientMonitor_endSessionWasCalled)
        XCTAssertEqual(capturedState, ProfileDriver.EndMonitoringState.none)
    }
}

private extension ALTPatient {
    static func mock(
        id: String = "patient1"
    ) -> ALTPatient {
        ALTPatient(
            hospitalRoomBedId: "hospital-room",
            heightIn: 20,
            weightLbs: 20,
            hasPaceMaker: false,
            hasSternumSkinBroken: false,
            sex: .female,
            bmi: 1,
            props: "contra",
            id: id
        )
    }
}

private extension UnitRoomModel {
    static func mock() -> UnitRoomModel {
        UnitRoomModel(
            facilityName: "facility1",
            facilityId: UUID(uuidString: "ec000641-1a30-44fa-9cdf-e1257e7f47be")!,
            units: [.mock(id: "0"), .mock(id: "1")],
            roomBeds: [.mock(id: "0", unit: "0"), .mock(id: "1", unit: "0"), .mock(id: "2", unit: "1")]
        )
    }
}

private extension HospitalUnit {
    static func mock(id: String) -> HospitalUnit {
        HospitalUnit(
            id: id,
            facilityId: "facility1",
            departmentId: "dept1",
            name: String(id),
            status: "dandy",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }
}

private extension HospitalRoomBed {
    static func mock(id: String, unit: String) -> HospitalRoomBed {
        HospitalRoomBed(
            id: id,
            facilityUnitId: unit,
            roomBedNumber: id,
            status: "great",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }
}
