//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM
import XCTest

final class HospitalRoomBedRepositoryTests: XCTestCase {
    var database: GRDBStorageService!
    var testSubject: HospitalRoomBedRepository!

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
        testSubject = HospitalRoomBedRepository(database)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testSubject = nil
        database = nil
    }

    func testGetRoomBedByID() async throws {
        // GIVEN - a populated database
        try await populateDatabase()

        // WHEN - we fetch a room bed by ID
        let roomBed = testSubject.getRoomBed(forId: "1")

        // THEN - We expect to have the specified roomBed
        let expected = HospitalRoomBed.mocks[optional: 1]
        XCTAssertEqual(roomBed, expected)
    }
}

private extension HospitalRoomBedRepositoryTests {
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
