//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM
import XCTest

final class HospitalUnitRepositoryTests: XCTestCase {
    var database: GRDBStorageService!
    var roomBedRepository: HospitalRoomBedRepository!
    var testSubject: HospitalUnitRepository!

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
        roomBedRepository = HospitalRoomBedRepository(database)
        testSubject = HospitalUnitRepository(database)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testSubject = nil
        roomBedRepository = nil
        database = nil
    }

    func testGetAll() async throws {
        // GIVEN - we have a populated database
        try await populateDatabase()

        // WHEN - we get all units
        let result = await testSubject.getAll()

        // THEN -
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result[optional: 0]?.roomBeds.count, 3)
        XCTAssertEqual(result[optional: 1]?.roomBeds.count, 3)
        XCTAssertEqual(result[optional: 2]?.roomBeds.count, 1)
    }

    func testUpdate() async throws {
        try await populateDatabase()
        let existing = await testSubject.getAll()
        var newUnits = HospitalUnit.mocks
        
        let new1 = HospitalUnit(
            id: "1",
            facilityId: newUnits[1].facilityId,
            departmentId: "dp2",
            name: newUnits[1].name,
            status: newUnits[1].status,
            lastModified: .now,
            lastModifiedBy: newUnits[1].lastModifiedBy,
            serverLastModified: newUnits[1].serverLastModified
        )
        newUnits[1] = new1
        newUnits.remove(at: 2)
        newUnits.append(.mock(id: "69"))

        var newRooms = HospitalRoomBed.mocks
        newRooms.remove(at: 6)
        newRooms.append(contentsOf: [.mock(id: "45", unitID: "69"), .mock(id: "46", unitID: "69")])

        let (unitDiff, roomDiff) = testSubject.update(
            newUnits: newUnits,
            newRoomBeds: newRooms,
            existing: existing,
            roomBedRepository: roomBedRepository
        )

        XCTAssertEqual(unitDiff.new.count, 1)
        XCTAssertEqual(unitDiff.unchanged.count, 3)
        XCTAssertEqual(unitDiff.removed.count, 1)
        XCTAssertEqual(unitDiff.new.count, 1)

        XCTAssertEqual(roomDiff.new.count, 2)
        XCTAssertEqual(roomDiff.unchanged.count, 6)
        XCTAssertEqual(roomDiff.removed.count, 1)
        XCTAssertEqual(roomDiff.new.count, 2)

        let unitResults = try await database.reader.read { db in
            try HospitalUnit.fetchAll(db).sorted { $0.id < $1.id }
        }

        XCTAssertEqual(unitResults[optional: 0], HospitalUnit.mocks.first)
        XCTAssertEqual(unitResults[optional: 1]?.id, new1.id)
        XCTAssertEqual(unitResults[optional: 1]?.facilityId, new1.facilityId)
        XCTAssertEqual(unitResults[optional: 1]?.departmentId, new1.departmentId)
        XCTAssertEqual(unitResults[optional: 1]?.name, new1.name)
        XCTAssertEqual(unitResults[optional: 1]?.status, new1.status)
        XCTAssertEqual(unitResults[optional: 1]?.lastModifiedBy, new1.lastModifiedBy)
        XCTAssertEqual(
            unitResults[1].serverLastModified.timeIntervalSinceReferenceDate,
            new1.serverLastModified.timeIntervalSinceReferenceDate,
            accuracy: 1e-12
        )
        guard unitResults.count > 1 else { return }
        XCTAssertEqual(
            unitResults[1].lastModified.timeIntervalSinceReferenceDate,
            new1.lastModified.timeIntervalSinceReferenceDate,
            accuracy: 1e-3
        )
    }
}

private extension HospitalUnitRepositoryTests {
    func populateDatabase() async throws {
        for unit in HospitalUnit.mocks {
            try await database.writer.write { db in
                var mutable = unit
                try mutable.insert(db)
            }
        }
        for room in HospitalRoomBed.mocks {
            try await database.writer.write { db in
                var mutable = room
                try mutable.insert(db)
            }
        }
    }
}

private extension HospitalUnit {
    static func mock(
        id: String
    ) -> HospitalUnit {
        HospitalUnit(
            id: id,
            facilityId: "facility1",
            departmentId: "dept1",
            name: "Unit \(id)",
            status: "lovely",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }

    static var mocks: [HospitalUnit] {
        [
            .mock(id: "0"),
            .mock(id: "1"),
            .mock(id: "2"),
            .mock(id: "3"),
            .mock(id: "4"),
        ]
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
            status: "frightful",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }

    static var mocks: [HospitalRoomBed] {
        [
            .mock(id: "0", unitID: "0"),
            .mock(id: "1", unitID: "0"),
            .mock(id: "2", unitID: "0"),
            .mock(id: "3", unitID: "1"),
            .mock(id: "4", unitID: "1"),
            .mock(id: "5", unitID: "1"),
            .mock(id: "6", unitID: "2"),
        ]
    }
}
