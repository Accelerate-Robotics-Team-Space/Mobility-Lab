//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM
import XCTest

final class RevokedCertificateRepositoryTests: XCTestCase {
    var database: GRDBStorageService!
    var testSubject: RevokedCertificateRepository!

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
        testSubject = RevokedCertificateRepository(database)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testSubject = nil
        database = nil
    }

    func testDeleteAllFromDB() async throws {
        // GIVEN - a populated DB
        for cert in RevokedCertificate.mocks {
            try await database.writer.write { db in
                var mutable = cert
                try mutable.insert(db)
            }
        }

        let certCountInitial = try await database.reader.read { db in
            try RevokedCertificate.fetchCount(db)
        }
        XCTAssertEqual(certCountInitial, 8)

        // WHEN - delete all is called
        testSubject.deleteAllFromDB()

        try await Task.sleep(nanoseconds: 2_000_000)

        // THEN - we expect to have
        let certCountFinal = try await database.reader.read { db in
            try RevokedCertificate.fetchCount(db)
        }
        XCTAssertEqual(certCountFinal, 0)
    }

    func testSaveToDBWithResult() async throws {
        // GIVEN - an empty DB

        // WHEN - we save a record
        let expected: RevokedCertificate = .mock(id: 69)
        var capturedResult: RevokedCertificate?
        let exp = expectation(description: #function)
        testSubject.saveToDB(expected) { result in
            switch result {
            case .success(let cert):
                capturedResult = cert
            case .failure(let error):
                XCTFail("Save Failed: \(error)")
            }
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: 2)

        XCTAssertEqual(capturedResult, expected)
    }

    func testSyncLoadAllFromDB() async throws {
        // GIVEN - a populated DB
        for cert in RevokedCertificate.mocks {
            try await database.writer.write { db in
                var mutable = cert
                try mutable.insert(db)
            }
        }

        let certCountInitial = try await database.reader.read { db in
            try RevokedCertificate.fetchCount(db)
        }
        XCTAssertEqual(certCountInitial, 8)

        // WHEN - all records are fetched
        let result = testSubject.syncLoadAllFromDB()

        XCTAssertEqual(result.count, 8)
    }
}

private extension RevokedCertificate {
    static func mock(id: Int) -> RevokedCertificate {
        RevokedCertificate(
            serialNum: id,
            revokedOn: "On top of a building",
            revokedBy: "Mr. Revoker",
            reason: "Because I could"
        )
    }

    static var mocks: [RevokedCertificate] {
        [
            .mock(id: 0),
            .mock(id: 1),
            .mock(id: 2),
            .mock(id: 3),
            .mock(id: 4),
            .mock(id: 5),
            .mock(id: 6),
            .mock(id: 7),
        ]
    }
}
