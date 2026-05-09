//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM
import XCTest

final class ErrorLogRepositoryTests: XCTestCase {
    var database: GRDBStorageService!
    var testSubject: ErrorLogRepository!

    fileprivate enum Error: Swift.Error, LocalizedError {
        case test

        var errorDescription: String? { "test" }
    }

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
        testSubject = ErrorLogRepository(database)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testSubject = nil
        database = nil
    }

    func testLoadAll() async throws {
        // GIVEN - a DB which is pre-populated with several Console Logs Items
        let expected = BMMErrorLog.testItems
        for item in expected {
            try await database.writer.write { db in
                var mutable = item
                try mutable.upsert(db)
            }
        }

        // WHEN - `loadAllFromDB` is called
        let exp = expectation(description: #function)
        var capturedResult: [BMMErrorLog] = []
        testSubject.loadAllFromDB { result in
            switch result {
            case .success(let value):
                capturedResult = value.sorted { ($0.id ?? -1) < ($1.id ?? -1) }
                exp.fulfill()
            case .failure(let error):
                XCTFail("Failed to load data \(error)")
                exp.fulfill()
            }
        }

        await fulfillment(of: [exp], timeout: 1)

        // THEN - We expect that we have all the same results
        XCTAssertEqual(capturedResult.count, 7)
        XCTAssertEqual(capturedResult[optional: 0]?.deviceUUID, "0")
        XCTAssertEqual(capturedResult[optional: 0]?.id, 1)
        XCTAssertEqual(capturedResult[optional: 0]?.dateCreated, .twenty25)
        XCTAssertEqual(capturedResult[optional: 0]?.error, "test")
        XCTAssertEqual(capturedResult[optional: 0], BMMErrorLog(error: ErrorLogRepositoryTests.Error.test, deviceUUID: "0", id: 1, date: .twenty25))
        XCTAssertEqual(capturedResult[optional: 3], BMMErrorLog(error: ErrorLogRepositoryTests.Error.test, deviceUUID: "3", id: 4, date: .twenty25))
        XCTAssertEqual(capturedResult[optional: 5], BMMErrorLog(error: ErrorLogRepositoryTests.Error.test, deviceUUID: "5", id: 6, date: .twenty25))
    }

    func testLoadByID() async throws {
        // GIVEN - a DB which is pre-populated with several Console Logs Items
        let expected = BMMErrorLog.testItems
        for item in expected {
            try await database.writer.write { db in
                var mutable = item
                try mutable.upsert(db)
            }
        }

        // WHEN - `loadAllFromDB` is called
        let exp = expectation(description: #function)
        var capturedResult: BMMErrorLog?
        testSubject.loadIdFromDB("5") { result in
            switch result {
            case .success(let value):
                capturedResult = value
                exp.fulfill()
            case .failure(let error):
                XCTFail("Failed to load data \(error)")
                exp.fulfill()
            }
        }

        await fulfillment(of: [exp], timeout: 1)

        // THEN - We expect that we have all the same results
        XCTAssertNotNil(capturedResult)
        XCTAssertEqual(capturedResult?.id, 5)
        XCTAssertEqual(capturedResult?.deviceUUID, "4")
        XCTAssertEqual(capturedResult?.error, "test")
    }

    func testAsyncSaveToDB() async throws {
        // GIVEN - a DB which is pre-populated with several Console Logs Items
        let expected: [BMMErrorLog] = [.mock(3), .mock(4)]
        for item in expected {
            try await database.writer.write { db in
                var mutable = item
                try mutable.upsert(db)
            }
        }

        // WHEN - a new Console log item is saved to the DB
        let newItem: BMMErrorLog = .mock(0)
        testSubject.syncSaveToDB(newItem)
        let saved = try await testSubject.asyncSaveToDB(newItem)

        XCTAssertEqual(saved.id, 4)
        XCTAssertEqual(saved.deviceUUID, "0")
        XCTAssertEqual(saved.error, "test")

        // THEN we expect it to be included in the DB contents
        let result = try await database.reader.read { db in
            try BMMErrorLog
                .fetchAll(db)
                .sorted { ($0.id ?? -1) < ($1.id ?? -1) }
        }

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[optional: 0]?.id, 1)
        XCTAssertEqual(result[optional: 0]?.error, "test")
        XCTAssertEqual(result[optional: 0]?.deviceUUID, "3")
        XCTAssertEqual(result[optional: 1]?.id, 2)
        XCTAssertEqual(result[optional: 2]?.id, 3)
    }

    func testDeleteIDs() async throws {
        let expected: [BMMErrorLog] = [
            .mock(3, id: 0),
            .mock(4, id: 1),
            .mock(2, id: 2),
            .mock(1, id: 3),
            .mock(1, id: 4),
        ]
        for item in expected {
            try await database.writer.write { db in
                var mutable = item
                try mutable.upsert(db)
            }
        }

        let ids = ["0", "2"]
        var capturedDeleteCount = 0
        let exp = expectation(description: #function)
        testSubject.deleteIdsFromDB(ids) { result in
            switch result {
            case .success(let deletedCount):
                capturedDeleteCount = deletedCount
                exp.fulfill()
            case .failure(let error):
                XCTFail("Failed to delete ids \(ids): \(error)")
                exp.fulfill()
            }
        }

        await fulfillment(of: [exp], timeout: 1)
        XCTAssertEqual(capturedDeleteCount, 2)

        let result = try await database.reader.read { db in
            try BMMErrorLog
                .fetchAll(db)
        }

        XCTAssertEqual(result.count, 3)
        XCTAssertFalse(result.map(\.id).contains(0))
        XCTAssertTrue(result.map(\.id).contains(1))
        XCTAssertFalse(result.map(\.id).contains(2))
        XCTAssertTrue(result.map(\.id).contains(3))
        XCTAssertTrue(result.map(\.id).contains(4))
    }
}

private extension BMMErrorLog {
    static var testItems: [BMMErrorLog] {
        [.mock(0), .mock(1), .mock(2), .mock(3), .mock(4), .mock(5), .mock(6)]
    }

    static func mock(_ guid: Int, id: Int64? = nil) -> BMMErrorLog {
        BMMErrorLog(
            error: ErrorLogRepositoryTests.Error.test,
            deviceUUID: String(guid),
            id: id,
            date: .twenty25
        )
    }
}
