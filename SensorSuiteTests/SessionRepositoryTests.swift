//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB
@testable import SensorSuite_BMM
import XCTest

final class SessionRepositoryTests: XCTestCase {
    var database: GRDBStorageService!
    var patientRepository: MockPatientRepository!
    var testSubject: SessionRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        patientRepository = MockPatientRepository()
        let configuration = GRDBConfiguration(storageLocation: .inMemory)
        let fileService = MockFileService()
        database = try GRDBStorageService(
            fileService: fileService,
            configuration: configuration,
            migrationsList: Migrations.self,
            migrationTarget: .specific(Initial_20260203.self)
        )
        testSubject = SessionRepository(grdbService: database, patientRepository: patientRepository)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testSubject = nil
        patientRepository = nil
        database = nil
    }

    func testGetLastSession_success() async throws {
        let expectedPatient = ALTPatient.mock(id: "patient1", roomBed: "roomBed1")
        let expectedSession = try await populate(sessionID: "1")
        var capturedID: String?
        patientRepository.getPatientByIDHandler = { id in
            capturedID = id
            return expectedPatient
        }

        let lastSession = await testSubject.getLastSession()

        XCTAssertEqual(lastSession?.id, expectedSession.id)
        XCTAssertEqual(lastSession?.patientId, expectedSession.patientId)
        XCTAssertEqual(lastSession?.positionsToAvoid, expectedSession.positionsToAvoid)
        XCTAssertEqual(lastSession?.turningProtocol, expectedSession.turningProtocol)
        XCTAssertEqual(lastSession?.patient, expectedPatient)
        XCTAssertEqual(capturedID, "patient1")
    }

    func testGetLastSession_noElement() async throws {
        patientRepository.getPatientByIDHandler = { _ in
            nil
        }

        let lastSession = await testSubject.getLastSession()

        XCTAssertNil(lastSession)
    }

    func testGetSessionByID_success() async throws {
        let expectedPatient = ALTPatient.mock(id: "patient1", roomBed: "roomBed1")
        let expectedSession = try await populate(sessionID: "3")
        var capturedID: String?
        patientRepository.getPatientByIDHandler = { id in
            capturedID = id
            return expectedPatient
        }

        let session = try await testSubject.getSession(withID: "3")

        XCTAssertEqual(session.id, expectedSession.id)
        XCTAssertEqual(session.patientId, expectedSession.patientId)
        XCTAssertEqual(session.positionsToAvoid, expectedSession.positionsToAvoid)
        XCTAssertEqual(session.turningProtocol, expectedSession.turningProtocol)
        XCTAssertEqual(session.patient, expectedPatient)
        XCTAssertEqual(capturedID, "patient1")
    }

    func testGetSessionByID_notFound() async throws {
        _ = try await populate(sessionID: "12")

        do {
            _ = try await testSubject.getSession(withID: "3")
        } catch let error as SensorSuite_BMM.PersistenceError {
            switch error {
            case SensorSuite_BMM.PersistenceError.noElementFound(let description):
                XCTAssertEqual(description, "SessionRepository.getSession(withID:)")
                XCTAssertTrue(true, "Expected Error was thrown")
            default:
                XCTFail("Unknown Error was thrown: \(error)")
            }
        } catch {
            XCTFail("Unknown Error was thrown: \(error)")
        }
    }

    func testNewSessionWithPatient() async throws {
        let expectedPatient = ALTPatient.mock(id: "patient1", roomBed: "roomBed1")
        _ = try await populate(sessionID: "23")
        var capturedID: String?
        patientRepository.getPatientByIDHandler = { id in
            capturedID = id
            return expectedPatient
        }

        let session = await testSubject.getSession(patientId: "patient1", turningProtocol: .q3Turn, positionsToAvoid: .supine)

        XCTAssertEqual(session.patientId, "patient1")
        XCTAssertEqual(session.positionsToAvoid, PositionalFlags.supine.rawValue)
        XCTAssertEqual(session.turningProtocol, .q3Turn)
        XCTAssertEqual(session.patient, expectedPatient)
        XCTAssertEqual(capturedID, "patient1")
    }

    func testNewSessionNoPatient() async throws {
        _ = try await populate(sessionID: "45")
        var capturedID: String?
        patientRepository.getPatientByIDHandler = { id in
            capturedID = id
            return nil
        }

        let session = await testSubject.getSession(patientId: "patient1", turningProtocol: .q3Turn, positionsToAvoid: .supine)

        XCTAssertEqual(session.patientId, "patient1")
        XCTAssertEqual(session.positionsToAvoid, PositionalFlags.supine.rawValue)
        XCTAssertEqual(session.turningProtocol, .q3Turn)
        XCTAssertNil(session.patient)
        XCTAssertEqual(capturedID, "patient1")
    }
}

private extension SessionRepositoryTests {
    func populate(sessionID: String) async throws -> ALTSession {
        let unit = HospitalUnit.mock(id: "unit1")
        let room = HospitalRoomBed.mock(id: "roomBed1", unitID: "unit1")
        let patient = ALTPatient.mock(id: "patient1", roomBed: "roomBed1")
        let session = ALTSession.mock(id: sessionID, patientID: "patient1")

        try await database.writer.write { db in
            var mutable = unit
            try mutable.insert(db)
        }
        try await database.writer.write { db in
            var mutable = room
            try mutable.insert(db)
        }
        try await database.writer.write { db in
            var mutable = patient
            try mutable.insert(db)
        }
        try await database.writer.write { db in
            var mutable = session
            try mutable.insert(db)
        }
        return session
    }
}

private extension ALTSession {
    static func mock(
        id: String,
        patientID: String,
        turningProtocol: TurningProtocol = .superShort,
        positionsToAvoid: PositionalFlags = .walking
    ) -> ALTSession {
        ALTSession(
            patientId: patientID,
            turningProtocol: turningProtocol,
            positionsToAvoid: positionsToAvoid,
            id: id
        )
    }
}

private extension ALTPatient {
    static func mock(
        id: String,
        roomBed: String,
        height: Int = 100,
        weight: Int = 100,
        pacemaker: Bool = false,
        sternumSkinBroken: Bool = false,
        sex: ALTSex = .female,
        bmi: Double = 1,
        props: String = "props"
    ) -> ALTPatient {
        ALTPatient(
            hospitalRoomBedId: roomBed,
            heightIn: height,
            weightLbs: weight,
            hasPaceMaker: pacemaker,
            hasSternumSkinBroken: sternumSkinBroken,
            sex: sex,
            bmi: bmi,
            props: props,
            id: id
        )
    }
}

private extension HospitalRoomBed {
    static func mock(
        id: String,
        unitID: String,
        roomBedNumber: String? = nil
    ) -> HospitalRoomBed {
        HospitalRoomBed(
            id: id,
            facilityUnitId: unitID,
            roomBedNumber: roomBedNumber ?? "room \(id)",
            status: "fantastic",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }
}

private extension HospitalUnit {
    static func mock(id: String) -> HospitalUnit {
        HospitalUnit(
            id: id,
            facilityId: "facility1",
            departmentId: "department1",
            name: "Unit \(id)",
            status: "great",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }
}
