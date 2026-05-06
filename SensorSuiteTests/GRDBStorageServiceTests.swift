//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB
@testable import SensorSuite_BMM
import XCTest

final class GRDBStorageServiceTests: XCTestCase {

    private var mockFileService: MockFileService!
    private var realFileService: FileService!

    override func setUp() {
        super.setUp()
        self.mockFileService = MockFileService()
        self.realFileService = FileService()
    }

    override func tearDown() {
        realFileService = nil
        mockFileService = nil
    }

    func testCreateInMemoryDatabase() {
        do {
            let configuration = GRDBConfiguration(storageLocation: .inMemory)
            _ = try GRDBStorageService(
                fileService: mockFileService,
                configuration: configuration,
                migrationsList: MigrationList1.self,
                migrationTarget: .none
            )
            XCTAssertTrue(true, "No Errors thrown")
        } catch {
            XCTFail("Failure initializing in memory database")
        }
    }

    func testCreateOnDiskDatabase() {
        do {
            let configuation = GRDBConfiguration(storageLocation: .onDisk(name: "create"))
            _ = try GRDBStorageService(
                fileService: self.realFileService,
                configuration: configuation,
                migrationsList: MigrationList1.self,
                migrationTarget: .none
            )
        } catch {
            XCTFail("Errors were thrown creating on-disk database")
        }
    }

    func testMigrateToSpecific() throws {
        let dbName = "specific"
        let configuation = GRDBConfiguration(storageLocation: .onDisk(name: dbName))
        let migrationTarget: GRDBStorageService.MigrationTarget = .specific(Migration1.self)

        let testSubject = try GRDBStorageService(
            fileService: self.realFileService,
            configuration: configuation,
            migrationsList: MigrationList1.self,
            migrationTarget: migrationTarget
        )

        let expectation = expectation(description: "migrateSpecific")
        var tableTest1Exists = false
        var tableTest2Exists = false
        try testSubject.reader.read { db in
            tableTest1Exists = try db.tableExists("test1")
            tableTest2Exists = try db.tableExists("test2")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        let pathTail = tail(of: testSubject.reader.path, directoryDepth: 3)
        XCTAssertEqual(pathTail, "Library/Application Support/\(dbName).sqlite")
        XCTAssertTrue(tableTest1Exists)
        XCTAssertFalse(tableTest2Exists)
    }

    func testMigrateToLatest() throws {
        let dbName = "latest"
        let configuation = GRDBConfiguration(storageLocation: .onDisk(name: dbName))
        let migrationTarget: GRDBStorageService.MigrationTarget = .latest

        let testSubject = try GRDBStorageService(
            fileService: self.realFileService,
            configuration: configuation,
            migrationsList: MigrationList1.self,
            migrationTarget: migrationTarget
        )

        let expectation = expectation(description: "migrateLatest")
        var tableTest1Exists = false
        var tableTest2Exists = false
        try testSubject.reader.read { db in
            tableTest1Exists = try db.tableExists("test1")
            tableTest2Exists = try db.tableExists("test2")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        let pathTail = tail(of: testSubject.reader.path, directoryDepth: 3)
        XCTAssertEqual(pathTail, "Library/Application Support/\(dbName).sqlite")
        XCTAssertTrue(tableTest1Exists)
        XCTAssertTrue(tableTest2Exists)
    }
}

private extension GRDBStorageServiceTests {
    func tail(of path: String, directoryDepth: Int) -> String {
        let pathComponents = path.split(separator: "/")
        let lastIndex = max(pathComponents.count - directoryDepth, 0)
        return pathComponents[lastIndex...].joined(separator: "/")
    }
}

private enum MigrationList1: MigrationsList {
    static var migrations: [Migration.Type] {
        [
            Migration1.self,
            Migration2.self,
        ]
    }
}

private class Migration1: Migration {
    override func perform(on database: Database) throws {
        try database.create(table: "test1") { definition in
            definition.column("id1", .integer).primaryKey().notNull()
            definition.column("name", .text).notNull()
        }
    }
}

private class Migration2: Migration {
    override func perform(on database: Database) throws {
        try database.create(table: "test2") { definition in
            definition.column("id2", .integer).primaryKey().notNull()
            definition.column("number", .integer).notNull()
        }
    }
}
