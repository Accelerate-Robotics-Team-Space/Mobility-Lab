//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
@testable import MobilityLab_BMM
import XCTest

final class PatientLocationDriverTests: XCTestCase {
    enum TestError: Error {
        case test
    }

    private var container: Container!
    private var hospitalUnitRepository: MockHospitalUnitRepository!
    private var hospitalRoomBedRepository: MockHospitalRoomBedRepository!
    private var sessionService: MockSessionService!
    private var patientManager: MockPatientManager!
    private var patientRepository: MockPatientRepository!
    private var provisioningAPIService: MockProvisioningAPIService!
    private var userDefaults: MockUserDefaultsService!

    private var testSubject: PatientLocationDriver!

    override func setUp() {
        super.setUp()
        container = .init()
        container.resetAll()

        sessionService = MockSessionService(currentSession: .mock(), turnTrackerInfo: .mock())
        patientManager = MockPatientManager()
        patientManager.session = sessionService
        let patient: ALTPatient = .mock()
        patientManager.cachePatient = patient
        patientManager.currentPatient = patient

        hospitalUnitRepository = MockHospitalUnitRepository()
        hospitalRoomBedRepository = MockHospitalRoomBedRepository()
        patientRepository = MockPatientRepository()
        provisioningAPIService = MockProvisioningAPIService()
        userDefaults = MockUserDefaultsService()

        hospitalUnitRepository.getAllHandler = { HospitalUnitInfo.mocks }
        hospitalUnitRepository.updateHandler = { _ in (units: .init(), rooms: .init()) }
        provisioningAPIService.getUnitRoomsHandler = { _ in Just(UnitRoomModel.mock()).setFailureType(to: Error.self).eraseToAnyPublisher() }

        container.hospitalUnitRepository.register { self.hospitalUnitRepository }
        container.hospitalRoomBedRepository.register { self.hospitalRoomBedRepository }
        container.patientRepository.register { self.patientRepository }
        container.provisioningAPIService.register { self.provisioningAPIService }
        container.userDefaults.register { self.userDefaults }

        testSubject = PatientLocationDriver(manager: patientManager, container: container)
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        patientManager = nil
        sessionService = nil
        hospitalUnitRepository = nil
        hospitalRoomBedRepository = nil
        patientRepository = nil
        provisioningAPIService = nil
        userDefaults = nil
        container = nil
    }

    func testSelectFirstRoomBed() {
        testSubject.selectFirstRoomBedItem()
        XCTAssertNil(testSubject.selectedRoomBed)
    }

    @MainActor
    func testSelectUnit() {
        let patient: ALTPatient = .mock(roomBed: "roomBed1", withRoomBed: false)
        patientManager.cachePatient = patient
        patientManager.currentPatient = patient
        let expected: [HospitalRoomBed] = [.mock("fum", unit: "0"), .mock("foo", unit: "0")]
        var capturedID: String?
        provisioningAPIService.getAvailableRoomBedHandler = { id in
            capturedID = id
            return Just(expected).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let unit = HospitalUnitInfo.mocks.first!
        let exp0 = expectation(description: #function)
        testSubject.selectUnit(unit) { error in
            XCTAssertNil(error)
            exp0.fulfill()
        }

        wait(for: [exp0], timeout: 2)

        XCTAssertEqual(capturedID, "0")
        XCTAssertEqual(testSubject.roomBedItems, expected.reversed())
        XCTAssertEqual(testSubject.selectedRoomBedStr, "Select your patient's room")
    }

    @MainActor
    func testSelectUnit_1Room() {
        let patient: ALTPatient = .mock(roomBed: "roomBed1", withRoomBed: false)
        patientManager.cachePatient = patient
        patientManager.currentPatient = patient
        let expected: HospitalRoomBed = .mock("fum", unit: "0")
        var capturedID: String?
        provisioningAPIService.getAvailableRoomBedHandler = { id in
            capturedID = id
            return Just([expected]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let unit = HospitalUnitInfo.mocks.first!
        let exp0 = expectation(description: #function)
        testSubject.selectUnit(unit) { error in
            XCTAssertNil(error)
            exp0.fulfill()
        }

        wait(for: [exp0], timeout: 2)

        XCTAssertEqual(capturedID, "0")
        XCTAssertEqual(testSubject.roomBedItems, [expected])
        XCTAssertEqual(testSubject.selectedRoomBed, expected)
    }

    func testGetUnitFromName() {
        let exp = expectation(description: "testGetUnitFromName - units updated")
        let cancellable = testSubject.$unitInfo.dropFirst().sink { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2)
        XCTAssertEqual(testSubject.getUnitFromName("0"), .mocks.first)
        XCTAssertNil(testSubject.getUnitFromName("bruce"))
        cancellable.cancel()
    }

    @MainActor
    func testGetRoomBedItemFromNumber() {
        let exp0 = expectation(description: "testGetUnitFromName - units updated")
        let cancellable = testSubject.$unitInfo.dropFirst().sink { _ in
            exp0.fulfill()
        }

        wait(for: [exp0], timeout: 2)

        let expected: [HospitalRoomBed] = [.mock("fum", unit: "0"), .mock("foo", unit: "0")]
        provisioningAPIService.getAvailableRoomBedHandler = { _ in
            return Just(expected).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let unit = HospitalUnitInfo.mocks.first!
        let exp1 = expectation(description: #function)
        testSubject.selectUnit(unit) { error in
            XCTAssertNil(error)
            exp1.fulfill()
        }

        wait(for: [exp1], timeout: 2)

        XCTAssertEqual(testSubject.getRoomBedItemFromNumber("foo"), .mock("foo", unit: "0"))
        XCTAssertNil(testSubject.getRoomBedItemFromNumber("bruce"))
        cancellable.cancel()
    }

    @MainActor
    func testGoNextBtnPress() {
        let exp0 = expectation(description: "testGoNextBtnPress - units updated")
        let cancellable = testSubject.$unitInfo.dropFirst().sink { _ in
            exp0.fulfill()
        }

        wait(for: [exp0], timeout: 2)

        let expected: [HospitalRoomBed] = [.mock("fum", unit: "0"), .mock("foo", unit: "0")]
        provisioningAPIService.getAvailableRoomBedHandler = { _ in
            return Just(expected).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let unit = HospitalUnitInfo.mocks.first!
        let exp1 = expectation(description: "testGoNextBtnPress - unit selected")
        testSubject.selectUnit(unit) { error in
            XCTAssertNil(error)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 2)

        testSubject.selectRoomBed(expected.first!)

        let exp2 = expectation(description: "testGoNextBtnPress - patient location updated")
        var capturedUnit: HospitalUnitInfo?
        var capturedRoom: HospitalRoomBed?
        patientManager.updatePatientLocationHandler = { unit, room in
            capturedUnit = unit
            capturedRoom = room
            exp2.fulfill()
        }

        let exp3 = expectation(description: "testGoNextBtnPress - no next")
        testSubject.goNextBtnPress {
            exp3.fulfill()
        }

        wait(for: [exp2, exp3], timeout: 2)

        XCTAssertNotNil(capturedUnit)
        XCTAssertNotNil(capturedRoom)
        XCTAssertEqual(capturedRoom, expected.first)
        cancellable.cancel()
    }

    @MainActor
    func testResetFromPatient() async {
        let expected: [HospitalRoomBed] = [.mock("fum", unit: "0"), .mock("foo", unit: "0")]
        provisioningAPIService.getAvailableRoomBedHandler = { _ in
            return Just(expected).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let exp0 = expectation(description: "testResetFromPatient - units updated")
        let cancellable0 = testSubject.$unitInfo.dropFirst().sink { _ in
            exp0.fulfill()
        }

        await fulfillment(of: [exp0], timeout: 2)

        let patient: ALTPatient = .mock(roomBed: "fum")
        patientManager.cachePatient = patient
        patientManager.currentPatient = patient

        let exp1 = expectation(description: "testResetFromPatient - selected roomBed str updated")
        let cancellable1 = testSubject.$selectedRoomBedStr.dropFirst().sink { _ in
            exp1.fulfill()
        }

        testSubject.resetFromPatient()
        await fulfillment(of: [exp1], timeout: 2)

        XCTAssertEqual(testSubject.selectedUnit, .mock("0", beds: [.mock("fum", unit: "0"), .mock("foo", unit: "0")]))
        XCTAssertEqual(testSubject.selectedRoomBed, .mock("fum", unit: "0"))
        cancellable0.cancel()
        cancellable1.cancel()
    }
}

private extension ALTPatient {
    static func mock(roomBed: String = "foo", withRoomBed: Bool = true) -> ALTPatient {
        var patient = ALTPatient(
            hospitalRoomBedId: roomBed,
            heightIn: 200,
            weightLbs: 100,
            hasPaceMaker: false,
            hasSternumSkinBroken: false,
            sex: .female,
            bmi: 1,
            props: "props",
            id: "test-id"
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
    static func mock() -> ALTSession {
        ALTSession(
            patientId: "mock-session-id",
            turningProtocol: .superShort,
            positionsToAvoid: .walking
        )
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
