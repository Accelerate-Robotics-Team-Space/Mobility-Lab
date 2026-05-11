//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB
@testable import MobilityLab_BMM
import XCTest

final class DatabaseManagementServiceTests: XCTestCase {
    enum TestError: Error {
        case test
    }

    var database: GRDBStorageService!
    var testSubject: DatabaseManagementService!

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
        testSubject = DatabaseManagementService(database)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testSubject = nil
        database = nil
    }
    
    func testResetTable() async throws {
        // GIVEN - we have a full set of populated tables
        try await populateAllTables()
        try await testCountAll()

        // WHEN - we call `resetTable`
        try await testSubject.resetTable()

        // THEN - 3 tables should be cleared
        try await testCount(ALTActivityLog.self, expected: 0)
        try await testCount(ALTPatient.self, expected: 0)
        try await testCount(ALTSession.self, expected: 0)

        // and the remaining tables are untouched
        try await testCount(HospitalUnit.self)
        try await testCount(RevokedCertificate.self)
        try await testCount(BMMErrorLog.self)
        try await testCount(ConsoleLogItem.self)
        try await testCount(HospitalRoomBed.self)
    }

    func testResetAll() async throws {
        // GIVEN - we have a full set of populated tables
        try await populateAllTables()
        try await testCountAll()

        // WHEN - we call `resetTable`
        try await testSubject.resetAll()

        // THEN - 6 tables should be cleared
        try await testCount(ALTActivityLog.self, expected: 0)
        try await testCount(ALTPatient.self, expected: 0)
        try await testCount(ALTSession.self, expected: 0)
        try await testCount(HospitalUnit.self, expected: 0)
        try await testCount(RevokedCertificate.self, expected: 0)
        try await testCount(HospitalRoomBed.self, expected: 0)

        // and the remaining tables are untouched
        try await testCount(BMMErrorLog.self)
        try await testCount(ConsoleLogItem.self)
    }
}

extension DatabaseManagementServiceTests {
    fileprivate protocol WithMockCount {
        static var mockCount: Int { get }
        static var mocks: [Self] { get }
    }

    private func populateAllTables() async throws {
        try await populateMocks(HospitalUnit.self)
        try await populateMocks(RevokedCertificate.self)
        try await populateMocks(BMMErrorLog.self)
        try await populateMocks(ConsoleLogItem.self)
        try await populateMocks(HospitalRoomBed.self)
        try await populateMocks(ALTPatient.self)
        try await populateMocks(ALTSession.self)
        try await populateMocks(ALTActivityLog.self)
    }

    private func testCountAll(file: StaticString = #filePath, line: UInt = #line) async throws {
        try await testCount(HospitalUnit.self, file: file, line: line)
        try await testCount(RevokedCertificate.self, file: file, line: line)
        try await testCount(BMMErrorLog.self, file: file, line: line)
        try await testCount(ConsoleLogItem.self, file: file, line: line)
        try await testCount(HospitalRoomBed.self, file: file, line: line)
        try await testCount(ALTPatient.self, file: file, line: line)
        try await testCount(ALTSession.self, file: file, line: line)
        try await testCount(ALTActivityLog.self, file: file, line: line)
    }

    private func count<T: DataStorable>(_ obj: T.Type) async throws -> Int {
        try await database.reader.read { db in
            try T.fetchCount(db)
        }
    }

    private func testCount<T: WithMockCount & DataStorable>(_ obj: T.Type, expected: Int? = nil, file: StaticString = #filePath, line: UInt = #line) async throws {
        let rows = try await count(obj)
        let expected = expected ?? obj.mockCount
        XCTAssertEqual(rows, expected, file: file, line: line)
    }

    private func populateMocks<T: WithMockCount & DataStorable>(_ obj: T.Type) async throws {
        for item in T.mocks {
            try await database.writer.write { db in
                var mutable = item
                try mutable.upsert(db)
            }
        }
    }
}

extension HospitalUnit: DatabaseManagementServiceTests.WithMockCount {
    private static func mock(
        id: String
    ) -> Self {
        .init(
            id: id,
            facilityId: "test-facility",
            departmentId: "dept1",
            name: "HospitalUnit \(id)",
            status: "bonza",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }

    fileprivate static var mockCount: Int { 100 }

    fileprivate static var mocks: [HospitalUnit] {
        (0..<mockCount).map(String.init).map(HospitalUnit.mock)
    }
}

extension HospitalRoomBed: DatabaseManagementServiceTests.WithMockCount {
    private static func mock(
        id: String,
        unitID: String,
        roomBedID: String
    ) -> Self {
        .init(
            id: id,
            facilityUnitId: unitID,
            roomBedNumber: roomBedID,
            status: "fantastic",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }

    fileprivate static var mockCount: Int { 100 }

    fileprivate static var mocks: [HospitalRoomBed] {
        (0..<mockCount).map { value in
            HospitalRoomBed.mock(id: String(value), unitID: String(value), roomBedID: String(value))
        }
    }
}

extension BMMErrorLog: DatabaseManagementServiceTests.WithMockCount {
    private static func mock(id: String) -> Self {
        .init(
            error: DatabaseManagementServiceTests.TestError.test,
            deviceUUID: id
        )
    }

    fileprivate static var mockCount: Int { 100 }

    fileprivate static var mocks: [BMMErrorLog] {
        (0..<mockCount).map(String.init).map(BMMErrorLog.mock)
    }
}

extension ConsoleLogItem: DatabaseManagementServiceTests.WithMockCount {
    private static func mock(id: Int64) -> Self {
        .init(
            id: id,
            message: "Test \(id)",
            date: .twenty25(plus: Double(id * 2))
        )
    }

    fileprivate static var mockCount: Int { 100 }

    fileprivate static var mocks: [ConsoleLogItem] {
        (Int64.zero..<Int64(mockCount)).map(ConsoleLogItem.mock)
    }
}

extension ALTPatient: DatabaseManagementServiceTests.WithMockCount {
    private static func mock(
        id: String,
        roomBedID: String
    ) -> Self {
        .init(
            hospitalRoomBedId: roomBedID,
            heightIn: 100,
            weightLbs: 100,
            hasPaceMaker: false,
            hasSternumSkinBroken: false,
            sex: .female,
            bmi: 1,
            props: "prop",
            id: id
        )
    }

    fileprivate static var mockCount: Int { 100 }

    fileprivate static var mocks: [ALTPatient] {
        (0..<mockCount).map(String.init).map { id in
            ALTPatient.mock(id: id, roomBedID: id)
        }
    }
}

extension ALTSession: DatabaseManagementServiceTests.WithMockCount {
    private static func mock(
        id: String,
        patientID: String
    ) -> Self {
        .init(
            patientId: patientID,
            turningProtocol: .q2Turn,
            positionsToAvoid: [.trendelenburg, .walking],
            id: id
        )
    }

    fileprivate static var mockCount: Int { 40 }

    fileprivate static var mocks: [ALTSession] {
        (0..<mockCount).map(String.init).map { ALTSession.mock(id: $0, patientID: $0) }
    }
}

extension ALTActivityLog: DatabaseManagementServiceTests.WithMockCount {
    private static func mock(
        id: Int64,
        patientID: String,
        sessionID: String,
        roomBedID: String
    ) -> Self {
        .init(
            patientID: patientID,
            sessionID: sessionID,
            actualPositionStarted: .twenty25,
            actualPositionEnded: .twenty25(plus: 300),
            actualPosition: .supine,
            startingTarget: .left,
            startingTimeRemaining: 20,
            endingTimeRemaining: 21,
            bmmMonitoringState: "going",
            bmmPauseReason: "none",
            isWrongPosition: false,
            hospitalRoomBedID: roomBedID,
            mqttTopicStr: "x/y/z/123",
            updateID: "update0",
            headOfBedAngle: 40,
            turnAngle: 40,
            endingTargetPosition: "foo",
            id: id,
            isCurrent: true,
            isSynced: false
        )
    }

    fileprivate static var mockCount: Int { 100 }

    fileprivate static var mocks: [ALTActivityLog] {
        (Int64.zero..<Int64(mockCount)).map { id in
            ALTActivityLog.mock(
                id: id,
                patientID: String(id),
                sessionID: String(Int.random(in: 0..<ALTSession.mockCount)),
                roomBedID: String(id)
            )
        }
    }
}

extension RevokedCertificate: DatabaseManagementServiceTests.WithMockCount {
    private static func mock(
        serialNumber: Int
    ) -> Self {
        .init(
            serialNum: serialNumber,
            revokedOn: "foo",
            revokedBy: "bar",
            reason: "buz"
        )
    }

    fileprivate static var mockCount: Int { 10 }

    fileprivate static var mocks: [RevokedCertificate] {
        (0..<mockCount).map(RevokedCertificate.mock)
    }
}
