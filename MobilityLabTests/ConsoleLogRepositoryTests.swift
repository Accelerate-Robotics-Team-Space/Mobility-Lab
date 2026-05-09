//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM
import XCTest

final class ConsoleLogRepositoryTests: XCTestCase {
    var database: GRDBStorageService!
    var testSubject: ConsoleLogRepository!

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
        testSubject = ConsoleLogRepository(database)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testSubject = nil
        database = nil
    }

    func testLoadAll() async throws {
        // GIVEN - a DB which is pre-populated with several Console Logs Items
        let expected = ConsoleLogItem.testItems
        for item in expected {
            try await database.writer.write { db in
                var mutable = item
                try mutable.upsert(db)
            }
        }

        // WHEN - `loadAllFromDB` is called
        let result = await testSubject.loadAllFromDB()

        // THEN - We expect that we have all the same results
        XCTAssertEqual(result.count, 7)
        XCTAssertEqual(result[optional: 0], ConsoleLogItem(id: 0, message: "Item 0", date: .twenty25))
        XCTAssertEqual(result[optional: 3], ConsoleLogItem(id: 3, message: "Item 3", date: .twenty25(plus: 30)))
        XCTAssertEqual(result[optional: 5], ConsoleLogItem(id: 5, message: "Item 5", date: .twenty25(plus: 50)))
    }

    func testLoadByID() async throws {
        // GIVEN - a DB which is pre-populated with several Console Logs Items
        let expected = ConsoleLogItem.testItems
        for item in expected {
            try await database.writer.write { db in
                var mutable = item
                try mutable.upsert(db)
            }
        }

        // WHEN - `loadAllFromDB` is called
        let result = await testSubject.loadIdFromDB("5")

        // THEN - We expect that we have all the same results
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, 5)
        XCTAssertEqual(result?.message, "Item 5")
        XCTAssertEqual(result?.date, .twenty25(plus: 50))
    }

    func testSyncSaveToDB() async throws {
        // GIVEN - a DB which is pre-populated with several Console Logs Items
        let expected: [ConsoleLogItem] = [.mock(3), .mock(4)]
        for item in expected {
            try await database.writer.write { db in
                var mutable = item
                try mutable.upsert(db)
            }
        }

        // WHEN - a new Console log item is saved to the DB
        let newItem: ConsoleLogItem = .mock(0)
        testSubject.syncSaveToDB(newItem)

        // THEN we expect it to be included in the DB contents
        let result = try await database.reader.read { db in
            try ConsoleLogItem
                .fetchAll(db)
                .sorted { ($0.id ?? -1) < ($1.id ?? -1) }
        }

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[optional: 0]?.id, 0)
        XCTAssertEqual(result[optional: 0]?.message, "Item 0")
        XCTAssertEqual(result[optional: 1]?.id, 3)
        XCTAssertEqual(result[optional: 2]?.id, 4)
    }

    func testSyncSaveAndFetch() async throws {
        let expected: [ConsoleLogItem] = [.mock(3), .mock(4)]
        for item in expected {
            try await database.writer.write { db in
                var mutable = item
                try mutable.upsert(db)
            }
        }

        let newItem = ConsoleLogItem(message: "A Log Item With No ID", date: .twenty25(plus: 500))
        let result = try testSubject.syncSaveAndFetch(newItem)
        XCTAssertEqual(newItem.message, result.message)
        XCTAssertEqual(newItem.date, result.date)
        XCTAssertNil(result.id) // for some reason this returns as `nil` on an ephemeral database.
    }

    func testDeleteOldItemsBelowOffset() async throws {
        let prePopulated: [ConsoleLogItem] = (Int64(0)..<1000).map(ConsoleLogItem.mock)
        for item in prePopulated {
            try await database.writer.write { db in
                var mutable = item
                try mutable.upsert(db)
            }
        }

        // This should delete 500 records
        // max(0, 300 - 500), offset by 500
        testSubject.deleteOldItems(totalCount: 300)

        // Shouldn't be needed, but this makes the test a bit less flakey
        try? await Task.sleep(nanoseconds: 2_000_000)

        let result = try await database.reader.read { db in
            try ConsoleLogItem.fetchAll(db).sorted(by: { ($0.id ?? -1) < ($1.id ?? -1) })
        }

        XCTAssertEqual(result.count, 500)
        XCTAssertEqual(result.first?.id, 500)
        XCTAssertEqual(result[optional: 4]?.id, 504)
        XCTAssertEqual(result[optional: 300]?.id, 800)
        XCTAssertEqual(result[optional: 400]?.id, 900)
        XCTAssertEqual(result.last?.id, 999)
    }

    func testDeleteOldItemsAboveOffset() async throws {
        let prePopulated: [ConsoleLogItem] = (Int64(0)..<1000).map(ConsoleLogItem.mock)
        for item in prePopulated {
            try await database.writer.write { db in
                var mutable = item
                try mutable.upsert(db)
            }
        }

        // This should delete 299 records (800 - 500)
        // max(0, 800 - 500), offset by 500
        testSubject.deleteOldItems(totalCount: 800)

        // Shouldn't be needed, but this makes the test a bit less flakey
        try? await Task.sleep(nanoseconds: 2_000_000)

        let result = try await database.reader.read { db in
            try ConsoleLogItem.fetchAll(db).sorted(by: { ($0.id ?? -1) < ($1.id ?? -1) })
        }

        XCTAssertEqual(result.count, 700)
        XCTAssertEqual(result[optional: 0]?.id, 0)
        XCTAssertEqual(result[optional: 4]?.id, 4)
        XCTAssertEqual(result[optional: 10]?.id, 10)
        XCTAssertEqual(result[optional: 100]?.id, 100)
        XCTAssertEqual(result[optional: 101]?.id, 101)
        XCTAssertEqual(result[optional: 199]?.id, 199)
        // The 299 records are removed from here (offset by 500) - items 200-499
        XCTAssertEqual(result[optional: 200]?.id, 500)
        XCTAssertEqual(result[optional: 300]?.id, 600)
        XCTAssertEqual(result[optional: 400]?.id, 700)
        XCTAssertEqual(result[optional: 698]?.id, 998)
        XCTAssertEqual(result[optional: 699]?.id, 999)
    }
}

private extension ConsoleLogItem {
    static var testItems: [ConsoleLogItem] {
        [.mock(0), .mock(1), .mock(2), .mock(3), .mock(4), .mock(5), .mock(6)]
    }

    static func mock(_ id: Int64) -> ConsoleLogItem {
        ConsoleLogItem(
            id: id,
            message: "Item \(id)",
            date: .twenty25(plus: Double(id * 10))
        )
    }
}
