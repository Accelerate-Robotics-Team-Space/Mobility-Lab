//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB
@testable import SensorSuite_BMM
import XCTest

final class PatientRepositoryTests: XCTestCase {
    var database: GRDBStorageService!
    var testSubject: PatientRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let configuration = GRDBConfiguration(storageLocation: .inMemory)
        let fileService = MockFileService()
        database = try GRDBStorageService(
            fileService: fileService,
            configuration: configuration,
            migrationsList: Migrations.self,
            migrationTarget: .specific(Initial_20260203.self)
        )
        testSubject = PatientRepository(database)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testSubject = nil
        database = nil
    }

    func testUpdateLocation() async throws {
        // GIVEN - the database is populated with the Patient we want to update
        try await populateDB()

        // WHEN - we update the patient's location
        let unitTest: HospitalUnit = .mock(id: "test")
        let roomBedTest: HospitalRoomBed = .mock(id: "foo", unit: "test")
        let patient: ALTPatient = .mock(id: "0")
        let expected = PatientLocation(unit: unitTest, roomBed: roomBedTest)
        let result = await testSubject.updateLocation(for: patient, to: expected)

        // THEN - we expect the location to have updated
        let actualOptional = try await database.reader.read { db in
            try ALTPatient.fetchOne(db, id: "0")
        }

        let actual = try XCTUnwrap(actualOptional)
        XCTAssertEqual(result.id, actual.id)
        XCTAssertEqual(
            result.createdAt.timeIntervalSinceReferenceDate,
            actual.createdAt.timeIntervalSinceReferenceDate,
            accuracy: 1e-2
        )
        XCTAssertEqual(result.altPatientId, actual.altPatientId)
        XCTAssertEqual(result.hospitalRoomBedId, actual.hospitalRoomBedId)
        XCTAssertEqual(actual.hospitalRoomBedId, "foo")
        XCTAssertEqual(result.heightMeasurement, actual.heightMeasurement)
        XCTAssertEqual(result.weightMeasurement, actual.weightMeasurement)
        XCTAssertEqual(result.heightIn, actual.heightIn)
        XCTAssertEqual(result.weightLbs, actual.weightLbs)
        XCTAssertEqual(result.hasPaceMaker, actual.hasPaceMaker)
        XCTAssertEqual(result.hasSternumSkinBroken, actual.hasSternumSkinBroken)
        XCTAssertEqual(result.sex, actual.sex)
        XCTAssertEqual(result.bmi, actual.bmi)
        XCTAssertEqual(result.sensorLocation, actual.sensorLocation)
        XCTAssertEqual(result.positionToAvoid, actual.positionToAvoid)
        XCTAssertEqual(result.props, actual.props)
        XCTAssertEqual(result.hasPaceMaker, actual.hasPaceMaker)
        XCTAssertEqual(result.isSynced, actual.isSynced)
        XCTAssertEqual(result.isSyncedToDB, actual.isSyncedToDB)
        XCTAssertEqual(result.roomBed, roomBedTest)
    }

    func testUpdatePatientProfile() async throws {
        // GIVEN - the database is populated with the Patient we want to update
        try await populateDB()

        // WHEN - we update the patient's location
        let expected = ALTPatient.ProfileUpdate(
            height: 500,
            weight: 500,
            hasPaceMaker: true,
            hasSternumSkinBroken: false,
            sex: .other,
            bmi: 1.5,
            props: "constant-speed",
            altPatientId: "Alteration",
            sensorLocation: "forehead"
        )
        let patient: ALTPatient = .mock()
        guard let result = try await testSubject.update(patientID: patient.id, profile: expected) else {
            XCTFail("Patient Not Returned")
            return
        }

        // THEN - we expect the location to have updated
        let actualOptional = try await database.reader.read { db in
            try ALTPatient.fetchOne(db, id: "0")
        }

        let actual = try XCTUnwrap(actualOptional)
        XCTAssertEqual(result.id, actual.id)
        XCTAssertEqual(
            result.createdAt.timeIntervalSinceReferenceDate,
            actual.createdAt.timeIntervalSinceReferenceDate,
            accuracy: 1e-2
        )
        XCTAssertEqual(result.altPatientId, actual.altPatientId)
        XCTAssertEqual(result.hospitalRoomBedId, actual.hospitalRoomBedId)
        XCTAssertEqual(actual.hospitalRoomBedId, "room-0")
        XCTAssertEqual(result.heightMeasurement, actual.heightMeasurement)
        XCTAssertEqual(result.weightMeasurement, actual.weightMeasurement)
        XCTAssertEqual(result.heightIn, actual.heightIn)
        XCTAssertEqual(result.weightLbs, actual.weightLbs)
        XCTAssertEqual(result.hasPaceMaker, actual.hasPaceMaker)
        XCTAssertEqual(result.hasSternumSkinBroken, actual.hasSternumSkinBroken)
        XCTAssertEqual(result.sex, actual.sex)
        XCTAssertEqual(result.bmi, actual.bmi)
        XCTAssertEqual(result.sensorLocation, actual.sensorLocation)
        XCTAssertEqual(result.positionToAvoid, actual.positionToAvoid)
        XCTAssertEqual(result.props, actual.props)
        XCTAssertEqual(result.hasPaceMaker, actual.hasPaceMaker)
        XCTAssertEqual(result.isSynced, actual.isSynced)
        XCTAssertEqual(result.isSyncedToDB, actual.isSyncedToDB)
        XCTAssertEqual(result.heightIn, 500)
        XCTAssertEqual(result.weightLbs, 500)
        XCTAssertTrue(result.hasPaceMaker)
        XCTAssertFalse(result.hasSternumSkinBroken)
        XCTAssertEqual(result.sex, .other)
        XCTAssertEqual(result.bmi, 1.5)
        XCTAssertEqual(result.props, "constant-speed")
        XCTAssertEqual(result.altPatientId, "Alteration")
        XCTAssertEqual(result.sensorLocation, "forehead")
    }

    func testUpdateProps() async throws {
        // GIVEN - the database is populated with the Patient we want to update
        try await populateDB()

        // WHEN - we update the patient's location
        let expected = "forehead"
        let result = await testSubject.updateProps(for: .mock(), to: expected)

        // THEN - we expect the location to have updated
        let actualOptional = try await database.reader.read { db in
            try ALTPatient.fetchOne(db, id: "0")
        }

        let actual = try XCTUnwrap(actualOptional)
        XCTAssertEqual(result.id, actual.id)
        XCTAssertEqual(result.props, actual.props)
        XCTAssertEqual(result.props, "forehead")
    }

    func testUpdateAltPatientID() async throws {
        // GIVEN - the database is populated with the Patient we want to update
        try await populateDB()

        // WHEN - we update the patient's location
        let expected = "forehead"
        let result = await testSubject.updateAltPatientId(for: .mock(), to: expected)

        // THEN - we expect the location to have updated
        let actualOptional = try await database.reader.read { db in
            try ALTPatient.fetchOne(db, id: "0")
        }

        let actual = try XCTUnwrap(actualOptional)
        XCTAssertEqual(result.id, actual.id)
        XCTAssertEqual(result.altPatientId, actual.altPatientId)
        XCTAssertEqual(result.altPatientId, "forehead")
    }

    func testUpdateIsSynced() async throws {
        // GIVEN - the database is populated with the Patient we want to update
        try await populateDB()

        // WHEN - we update the patient's location
        let expected = true
        let result = await testSubject.updateIsSynced(for: .mock(), to: expected)

        // THEN - we expect the location to have updated
        let actualOptional = try await database.reader.read { db in
            try ALTPatient.fetchOne(db, id: "0")
        }

        let actual = try XCTUnwrap(actualOptional)
        XCTAssertEqual(result.id, actual.id)
        XCTAssertEqual(result.isSynced, actual.isSynced)
        XCTAssertTrue(result.isSynced ?? false)
    }

    func testFetchLatest() async throws {
        // GIVEN - the database is populated with the Patient we want to update
        try await populateDB()
        let morePatients: [ALTPatient] = (34..<45)
            .map { .mock(id: String($0), createdAt: .twenty25(plus: Double($0) * 100)) }
        for item in morePatients {
            try await database.writer.write { db in
                var mutable = item
                try mutable.insert(db)
            }
        }

        // WHEN - we update the patient's location
        let result = try await testSubject.latestPatient()

        // THEN - we expect the location to have updated
        let allPatients = try await database.reader.read { db in
            try ALTPatient
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "44")
        XCTAssertEqual(result?.id, allPatients.first?.id)
    }

    func testPrune() async throws {
        try await populateDB()
        let morePatients: [ALTPatient] = (1..<200)
            .map(String.init)
            .map { .mock(id: $0) }
        for item in morePatients {
            try await database.writer.write { db in
                var mutable = item
                try mutable.insert(db)
            }
        }

        testSubject.prune()

        try? await Task.sleep(nanoseconds: 0.9.nSec)

        let count = try await database.reader.read { db in
            try ALTPatient.fetchCount(db)
        }

        XCTAssertEqual(count, 10)
    }

    func testFetchNonSynced() async throws {
        try await populateDB()
        let morePatients: [ALTPatient] = (1..<280)
            .map { .mock(id: "\($0)", synced: $0 % 2 == 0) }
        for item in morePatients {
            try await database.writer.write { db in
                var mutable = item
                try mutable.insert(db)
            }
        }

        let count = try await database.reader.read { db in
            try ALTPatient.fetchCount(db)
        }

        XCTAssertEqual(count, 280)

        let result = testSubject.fetchNonSynced()

        XCTAssertEqual(result.count, 100)
        XCTAssertFalse(result.randomElement()?.isSynced ?? true)
    }

    func testGetPatientByID() async throws {
        try await populateDB()
        var morePatients: [ALTPatient] = (1..<200)
            .map(String.init)
            .map { .mock(id: $0) }
        let expected: ALTPatient = .mock(id: "test")
        morePatients.append(expected)
        for item in morePatients {
            try await database.writer.write { db in
                var mutable = item
                try mutable.insert(db)
            }
        }

        let resultOptional = await testSubject.getPatient(id: expected.id)

        let result = try XCTUnwrap(resultOptional)
        XCTAssertEqual(result.id, expected.id)
        XCTAssertEqual(
            result.createdAt.timeIntervalSinceReferenceDate,
            expected.createdAt.timeIntervalSinceReferenceDate,
            accuracy: 1e-1
        )
        XCTAssertEqual(result.altPatientId, expected.altPatientId)
        XCTAssertEqual(result.hospitalRoomBedId, expected.hospitalRoomBedId)
        XCTAssertEqual(result.heightMeasurement, expected.heightMeasurement)
        XCTAssertEqual(result.weightMeasurement, expected.weightMeasurement)
        XCTAssertEqual(result.heightIn, expected.heightIn)
        XCTAssertEqual(result.weightLbs, expected.weightLbs)
        XCTAssertEqual(result.hasPaceMaker, expected.hasPaceMaker)
        XCTAssertEqual(result.hasSternumSkinBroken, expected.hasSternumSkinBroken)
        XCTAssertEqual(result.sex, expected.sex)
        XCTAssertEqual(result.bmi, expected.bmi)
        XCTAssertEqual(result.sensorLocation, expected.sensorLocation)
        XCTAssertEqual(result.positionToAvoid, expected.positionToAvoid)
        XCTAssertEqual(result.props, expected.props)
        XCTAssertEqual(result.hasPaceMaker, expected.hasPaceMaker)
        XCTAssertEqual(result.isSynced, expected.isSynced)
        XCTAssertNotNil(result.roomBed)
    }
}

private extension PatientRepositoryTests {
    func populateDB() async throws {
        let unit: HospitalUnit = .mock(id: "0")
        let unitTest: HospitalUnit = .mock(id: "test")
        let roomBed0: HospitalRoomBed = .mock(id: "room-0", unit: "0")
        let roomBedTest: HospitalRoomBed = .mock(id: "foo", unit: "test")
        let patient: ALTPatient = .mock(id: "0")
        let units: [HospitalUnit] = [unit, unitTest]
        let roomBeds: [HospitalRoomBed] = [roomBed0, roomBedTest]
        for item in units {
            try await database.writer.write { db in
                var mutable = item
                try mutable.insert(db)
            }
        }
        for item in roomBeds {
            try await database.writer.write { db in
                var mutable = item
                try mutable.insert(db)
            }
        }
        try await database.writer.write { db in
            var mutable = patient
            try mutable.insert(db)
        }
    }
}

private extension ALTPatient {
    static func mock(
        id: String = "0",
        room: String = "room-0",
        synced: Bool = false,
        createdAt: Date = .twenty25
    ) -> ALTPatient {
        var patient = ALTPatient(
            hospitalRoomBedId: room,
            heightIn: 200,
            weightLbs: 100,
            hasPaceMaker: false,
            hasSternumSkinBroken: true,
            sex: .male,
            bmi: 20,
            props: "propeller",
            id: id,
            createdAt: createdAt
        )
        patient.isSynced = synced
        return patient
    }
}

private extension HospitalUnit {
    static func mock(id: String) -> HospitalUnit {
        HospitalUnit(
            id: id,
            facilityId: "facility1",
            departmentId: "dept0",
            name: id,
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
            roomBedNumber: "room-" + id,
            status: "fine",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }
}
