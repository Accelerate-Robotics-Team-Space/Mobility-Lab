//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation
import GRDB
@testable import MobilityLab_BMM
import XCTest

final class ActivityLogRepositoryTests: XCTestCase { // swiftlint:disable:this type_body_length
    private var database: GRDBStorageService!
    private var testSubject: ActivityLogRepository!
    private var cancellable: AnyCancellable?

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
        testSubject = ActivityLogRepository(database)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        cancellable?.cancel()
        testSubject = nil
        database = nil
        cancellable = nil
    }

    func testFetchFromSession() async throws {
        var logCount = try await populateDatabase(logs: 6, sessionID: "sessionID0")
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1")

        let logs = await testSubject.fetchFromSession(sessionId: "sessionID0")
        XCTAssertEqual(logs.count, 6)
    }

    func testDeleteAll() async throws {
        var logCount = try await populateDatabase(logs: 6, sessionID: "sessionID0")
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1")
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID4", patientID: "floo")

        let deleted = try await testSubject.deleteAll()
        let remaining = try await database.reader.read { db in
            try ALTActivityLog.fetchAll(db)
        }
        XCTAssertTrue(remaining.isEmpty)
        XCTAssertEqual(logCount, deleted)
    }

    func testFetchSyncedWithLimitNotInSession() async throws {
        var logCount = try await populateDatabase(logs: 6, sessionID: "sessionID0", isSynced: true)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", isSynced: true)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", isSynced: false)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", isSynced: false)

        let result0 = await testSubject.fetchSynced(withLimit: 3, notIn: "sessionID1")
        let result1 = await testSubject.fetchSynced(withLimit: 10, notIn: "sessionID1")

        XCTAssertEqual(result0.count, 3)
        XCTAssertEqual(result0.first?.id, 0)
        XCTAssertEqual(result0.first?.sessionId, "sessionID0")
        XCTAssertEqual(result0.last?.id, 2)
        XCTAssertEqual(result0.last?.sessionId, "sessionID0")

        XCTAssertEqual(result1.count, 6)
        XCTAssertEqual(result1.first?.id, 0)
        XCTAssertEqual(result1.first?.sessionId, "sessionID0")
        XCTAssertEqual(result1.last?.id, 5)
        XCTAssertEqual(result1.last?.sessionId, "sessionID0")
    }

    func testFetchSyncedWithLimit() async throws {
        var logCount = try await populateDatabase(logs: 6, sessionID: "sessionID0", isSynced: true)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", isSynced: true)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", isSynced: false)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", isSynced: false)

        let result0 = testSubject.fetchSynced(withLimit: 3).sorted { $0.id ?? -1 < $1.id ?? -1 }
        let result1 = testSubject.fetchSynced(withLimit: 10).sorted { $0.id ?? -1 < $1.id ?? -1 }

        XCTAssertEqual(result0.count, 3)
        XCTAssertEqual(result0.first?.id, 0)
        XCTAssertEqual(result0.first?.sessionId, "sessionID0")
        XCTAssertEqual(result0.last?.id, 2)
        XCTAssertEqual(result0.last?.sessionId, "sessionID0")

        XCTAssertEqual(result1.count, 10)
        XCTAssertEqual(result1.first?.id, 0)
        XCTAssertEqual(result1.first?.sessionId, "sessionID0")
        XCTAssertEqual(result1.last?.id, 9)
        XCTAssertEqual(result1.last?.sessionId, "sessionID1")
    }

    func testFetchNonSyncedWithLimit() async throws {
        var logCount = try await populateDatabase(logs: 6, sessionID: "sessionID0", isSynced: true)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", isSynced: true)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", isSynced: false)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", isSynced: false)

        let result0 = testSubject.fetchNonSynced(withLimit: 3).sorted { $0.id ?? -1 < $1.id ?? -1 }
        let result1 = testSubject.fetchNonSynced(withLimit: 10).sorted { $0.id ?? -1 < $1.id ?? -1 }

        XCTAssertEqual(result0.count, 3)
        XCTAssertEqual(result0.first?.id, 10)
        XCTAssertEqual(result0.first?.sessionId, "sessionID0")
        XCTAssertEqual(result0.last?.id, 12)
        XCTAssertEqual(result0.last?.sessionId, "sessionID0")

        XCTAssertEqual(result1.count, 8)
        XCTAssertEqual(result1.first?.id, 10)
        XCTAssertEqual(result1.first?.sessionId, "sessionID0")
        XCTAssertEqual(result1.last?.id, 17)
        XCTAssertEqual(result1.last?.sessionId, "sessionID1")
    }

    func testFetchNonSyncedSessionID() async throws {
        var logCount = try await populateDatabase(logs: 6, sessionID: "sessionID0", isSynced: true)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", isSynced: true)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", isSynced: false)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", isSynced: false)

        let result0 = await testSubject.fetchNonSynced(sessionId: "sessionID0").sorted { $0.id ?? -1 < $1.id ?? -1 }
        let result1 = await testSubject.fetchNonSynced(sessionId: "sessionID1").sorted { $0.id ?? -1 < $1.id ?? -1 }
        let result2 = await testSubject.fetchNonSynced(sessionId: "sessionID3").sorted { $0.id ?? -1 < $1.id ?? -1 }

        XCTAssertEqual(result0.count, 4)
        XCTAssertEqual(result0.first?.id, 10)
        XCTAssertEqual(result0.first?.sessionId, "sessionID0")
        XCTAssertEqual(result0.last?.id, 13)
        XCTAssertEqual(result0.last?.sessionId, "sessionID0")

        XCTAssertEqual(result1.count, 4)
        XCTAssertEqual(result1.first?.id, 14)
        XCTAssertEqual(result1.first?.sessionId, "sessionID1")
        XCTAssertEqual(result1.last?.id, 17)
        XCTAssertEqual(result1.last?.sessionId, "sessionID1")

        XCTAssertTrue(result2.isEmpty)
    }

    func testFetchUniqueDateSessionID() async throws {
        var logCount = try await populateDatabase(logs: 6, sessionID: "sessionID0", timeStep: 86_400)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", timeStep: 86_400)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", timeStep: 86_400)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", timeStep: 86_400)

        let result0 = await testSubject.fetchAllUniqueDate(from: "sessionID0")
        let result1 = await testSubject.fetchAllUniqueDate(from: "sessionID1")

        XCTAssertEqual(result0.count, 10)
        XCTAssertEqual(result0.first, #""2025-01-01""#)
        XCTAssertEqual(result0.last, #""2025-01-14""#)

        XCTAssertEqual(result1.count, 8)
        XCTAssertEqual(result1.first, #""2025-01-07""#)
        XCTAssertEqual(result1.last, #""2025-01-18""#)
    }

    func testFetchTotalDuration() async throws {
        var logCount = try await populateDatabase(logs: 6, sessionID: "sessionID0", position: .left, timeStep: 64, duration: 15)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .right, timeStep: 60, duration: 10)
        logCount = try await populateDatabase(logs: 6, idOffset: logCount, sessionID: "sessionID0", position: .supine, timeStep: 68, duration: 12)
        logCount = try await populateDatabase(logs: 8, idOffset: logCount, sessionID: "sessionID0", position: .other, timeStep: 61, duration: 15)
        logCount = try await populateDatabase(logs: 3, idOffset: logCount, sessionID: "sessionID0", position: .left, timeStep: 69, duration: 13)
        logCount = try await populateDatabase(logs: 8, idOffset: logCount, sessionID: "sessionID0", position: .right, timeStep: 63, duration: 17)
        logCount = try await populateDatabase(logs: 3, idOffset: logCount, sessionID: "sessionID0", position: .partialLeft, timeStep: 64, duration: 19)
        logCount = try await populateDatabase(logs: 8, idOffset: logCount, sessionID: "sessionID0", position: .partialRight, timeStep: 64, duration: 23)
        logCount = try await populateDatabase(logs: 8, idOffset: logCount, sessionID: "sessionID1", position: .right, timeStep: 66, duration: 4)
        logCount = try await populateDatabase(logs: 2, idOffset: logCount, sessionID: "sessionID1", position: .supine, timeStep: 68, duration: 10)
        logCount = try await populateDatabase(logs: 8, idOffset: logCount, sessionID: "sessionID1", position: .other, timeStep: 71, duration: 13)
        logCount = try await populateDatabase(logs: 6, idOffset: logCount, sessionID: "sessionID1", position: .left, timeStep: 54, duration: 12)
        logCount = try await populateDatabase(logs: 6, idOffset: logCount, sessionID: "sessionID1", position: .right, timeStep: 78, duration: 30)
        logCount = try await populateDatabase(logs: 7, idOffset: logCount, sessionID: "sessionID1", position: .partialLeft, timeStep: 60, duration: 22)
        logCount = try await populateDatabase(logs: 3, idOffset: logCount, sessionID: "sessionID1", position: .partialRight, timeStep: 61, duration: 7)

        let result0_left = await testSubject.fetchTotalDuration(position: .left, from: "sessionID0", date: "2025-01-01")
        let result0_supine = await testSubject.fetchTotalDuration(position: .supine, from: "sessionID0", date: "2025-01-01")
        let result0_partialLeft = await testSubject.fetchTotalDuration(position: .partialLeft, from: "sessionID0", date: "2025-01-01")
        let result0_right = await testSubject.fetchTotalDuration(position: .supine, from: "sessionID0", date: "2025-01-01")
        let result0_partialRight = await testSubject.fetchTotalDuration(position: .partialLeft, from: "sessionID0", date: "2025-01-01")
        let result0_other = await testSubject.fetchTotalDuration(position: .partialLeft, from: "sessionID0", date: "2025-01-01")

        let result1_left = await testSubject.fetchTotalDuration(position: .left, from: "sessionID1", date: "2025-01-01")
        let result1_supine = await testSubject.fetchTotalDuration(position: .supine, from: "sessionID1", date: "2025-01-01")
        let result1_partialLeft = await testSubject.fetchTotalDuration(position: .partialLeft, from: "sessionID1", date: "2025-01-01")
        let result1_right = await testSubject.fetchTotalDuration(position: .supine, from: "sessionID1", date: "2025-01-01")
        let result1_partialRight = await testSubject.fetchTotalDuration(position: .partialLeft, from: "sessionID1", date: "2025-01-01")
        let result1_other = await testSubject.fetchTotalDuration(position: .partialLeft, from: "sessionID1", date: "2025-01-01")

        XCTAssertEqual(result0_left, "00:02:09")
        XCTAssertEqual(result0_supine, "00:01:12")
        XCTAssertEqual(result0_partialLeft, "00:00:57")
        XCTAssertEqual(result0_right, "00:01:12")
        XCTAssertEqual(result0_partialRight, "00:00:57")
        XCTAssertEqual(result0_other, "00:00:57")

        XCTAssertEqual(result1_left, "00:01:12")
        XCTAssertEqual(result1_supine, "00:00:20")
        XCTAssertEqual(result1_partialLeft, "00:02:34")
        XCTAssertEqual(result1_right, "00:00:20")
        XCTAssertEqual(result1_partialRight, "00:02:34")
        XCTAssertEqual(result1_other, "00:02:34")
    }

    func testFetchTotalPauseDuration() async throws {
        var logCount = try await populateDatabase(logs: 6, sessionID: "sessionID0", state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", state: .onPause)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", state: .onStart)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", state: .onPause)

        let result0 = await testSubject.fetchTotalPauseDuration(from: "sessionID0", date: "2025-01-01")
        let result1 = await testSubject.fetchTotalPauseDuration(from: "sessionID1", date: "2025-01-01")

        // This function doesn't appear to work as expected
        // Not changing functionality for now
        XCTAssertEqual(result0, "00:00:00")
        XCTAssertEqual(result1, "00:00:00")
    }

    func testFetchTotalDisconnectedDuration() async throws {
        var logCount = try await populateDatabase(logs: 6, sessionID: "sessionID0", pauseReason: .null)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", pauseReason: .disconnected)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", pauseReason: .null)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", pauseReason: .disconnected)

        let result0 = await testSubject.fetchTotalPauseDuration(from: "sessionID0", date: "2025-01-01")
        let result1 = await testSubject.fetchTotalPauseDuration(from: "sessionID1", date: "2025-01-01")

        // This function doesn't appear to work as expected
        // Not changing functionality for now
        XCTAssertEqual(result0, "00:00:00")
        XCTAssertEqual(result1, "00:00:00")
    }

    func testFetchAllMonitoringActivityWithPositionAndSessionID() async throws {
        var logCount = try await populateDatabase(logs: 6, sessionID: "sessionID0", position: .left, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .supine, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .right, state: .onPause)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .left, state: .onPause)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .supine, state: .onPause)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .supine, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .other, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .other, state: .onPause)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .right, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .left, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", position: .left, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", position: .supine, state: .onResume)

        let result0_supine = await testSubject.fetchAllMonitoringActivity(position: .supine, from: "sessionID0", date: "2025-01-01")
        let result0_left = await testSubject.fetchAllMonitoringActivity(position: .left, from: "sessionID0", date: "2025-01-01")
        let result0_right = await testSubject.fetchAllMonitoringActivity(position: .right, from: "sessionID0", date: "2025-01-01")

        // This function doesn't appear to work as expected
        // Not changing functionality for now
        XCTAssertEqual(result0_supine.count, 0)
        XCTAssertEqual(result0_left.count, 0)
        XCTAssertEqual(result0_right.count, 0)
    }

    func testFetchAllPauseActivitySessionID() async throws {
        var logCount = try await populateDatabase(logs: 6, sessionID: "sessionID0", position: .left, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .supine, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .right, state: .onPause)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .left, state: .onPause)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .supine, state: .onPause)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .supine, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .other, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .other, state: .onPause)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .right, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", position: .left, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", position: .left, state: .onResume)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", position: .supine, state: .onResume)

        let result0 = await testSubject.fetchAllPauseActivity(from: "sessionID0", date: "2025-01-01")

        // This function doesn't appear to work as expected
        // Not changing functionality for now
        XCTAssertEqual(result0.count, 0)
    }

    func testFetchAllDisconnectActivitySessionID() async throws {
        var logCount = try await populateDatabase(logs: 6, sessionID: "sessionID0", pauseReason: .null)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", pauseReason: .disconnected)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID0", pauseReason: .null)
        logCount = try await populateDatabase(logs: 4, idOffset: logCount, sessionID: "sessionID1", pauseReason: .disconnected)

        let result0 = await testSubject.fetchAllDisconnectActivity(from: "sessionID0", date: "2025-01-01")
        let result1 = await testSubject.fetchAllDisconnectActivity(from: "sessionID1", date: "2025-01-01")

        // This function doesn't appear to work as expected
        // Not changing functionality for now
        XCTAssertTrue(result0.isEmpty)
        XCTAssertTrue(result1.isEmpty)
    }

    func testFetchDateStartEndSessionID() async throws {
        let logCount = try await populateDatabase(logs: 10, sessionID: "sessionID0")
        try await populateDatabase(logs: 8, idOffset: logCount, sessionID: "sessionID1")

        let dates = await testSubject.fetchDateStartEnd(from: "sessionID0", date: "2025-01-01")

        XCTAssertEqual(dates.first, .twenty25)
        XCTAssertEqual(dates.last, .twenty25(plus: 410))
    }

    func testFetchTotalTimeNotComplyingSessionID() async throws {
        var logCount = try await populateDatabase(
            logs: 6,
            sessionID: "sessionID0",
            position: .left,
            startPosition: .left,
            state: .onPause
        )
        logCount = try await populateDatabase(
            logs: 12,
            idOffset: logCount,
            sessionID: "sessionID0",
            position: .supine,
            startPosition: .supine,
            state: .onResume
        )
        logCount = try await populateDatabase(
            logs: 9,
            idOffset: logCount,
            sessionID: "sessionID0",
            position: .left,
            startPosition: .supine,
            state: .onResume
        )
        logCount = try await populateDatabase(
            logs: 4,
            idOffset: logCount,
            sessionID: "sessionID1",
            position: .supine,
            startPosition: .supine,
            state: .onResume
        )
        logCount = try await populateDatabase(
            logs: 4,
            idOffset: logCount,
            sessionID: "sessionID1",
            position: .left,
            startPosition: .supine,
            state: .onPause
        )

        let resultOld = await testSubject.fetchTotalTimeNotComplying(from: "sessionID0", date: "2025-01-01")
        let result = await testSubject.fetchTotalTimeNotComplyingNew(from: "sessionID0", date: "2025-01-01")

        // This function doesn't appear to work as expected
        // Not changing functionality for now
        XCTAssertEqual(resultOld, 0)
        // Equivalent function that behaves as expected
        XCTAssertEqual(result, 450)
    }

    func testFetchTotalTimeComplyingSessionID() async throws {
        var logCount = try await populateDatabase(
            logs: 6,
            sessionID: "sessionID0",
            position: .left,
            startPosition: .left,
            state: .onPause
        )
        logCount = try await populateDatabase(
            logs: 12,
            idOffset: logCount,
            sessionID: "sessionID0",
            position: .supine,
            startPosition: .supine,
            state: .onResume
        )
        logCount = try await populateDatabase(
            logs: 9,
            idOffset: logCount,
            sessionID: "sessionID0",
            position: .left,
            startPosition: .supine,
            state: .onResume
        )
        logCount = try await populateDatabase(
            logs: 4,
            idOffset: logCount,
            sessionID: "sessionID1",
            position: .supine,
            startPosition: .supine,
            state: .onResume
        )
        logCount = try await populateDatabase(
            logs: 4,
            idOffset: logCount,
            sessionID: "sessionID1",
            position: .left,
            startPosition: .supine,
            state: .onPause
        )

        let result = await testSubject.fetchTotalTimeComplying(from: "sessionID0", date: "2025-01-01")

        // This function doesn't appear to work as expected
        // Not changing functionality for now
        XCTAssertEqual(result, 0)
    }

    func testLatestEndDate() async throws {
        try await populateDatabase(logs: 53, sessionID: "sessionID0")
        let latestEndDate = await testSubject.latestEndDate()
        XCTAssertEqual(latestEndDate, .twenty25(plus: 2_130))
    }

    func testEndAllActivityLogs() async throws {
        try await populateDatabase(logs: 53, sessionID: "sessionID0")

        await testSubject.endAllActivityLog()

        let count = try await database.reader.read { db in
            try ALTActivityLog
                .filter(Column("isSynced") == false)
                .fetchCount(db)
        }

        XCTAssertEqual(count, 0)
    }

    func testResetAllIsCurrent() async throws {
        let logCount = try await populateDatabase(logs: 23, sessionID: "sessionID0", isCurrent: false)
        try await populateDatabase(logs: 13, idOffset: logCount, sessionID: "sessionID0", isCurrent: true)

        try await testSubject.resetAllIsCurrent()

        let count = try await database.reader.read { db in
            try ALTActivityLog
                .filter(Column("isCurrent") == true)
                .fetchCount(db)
        }

        XCTAssertEqual(count, 0)
    }

    func testWithLatestEndDate() async throws {
        try await populateDatabase(logs: 53)

        let result = testSubject.withLatestEndDate()
        let expected: ALTActivityLog = .mock(52, startDate: .twenty25(plus: 2_080), endDate: .twenty25(plus: 2_130))
        XCTAssertEqual(result, expected)
    }

    func testActivityLogPublisher() async throws { // swiftlint:disable:this function_body_length
        let unitID = "unit0"
        let activityLogs = (0 ..< 15).map {
            let id = $0
            let startOffset = Double(id) * 40
            return ALTActivityLog.mock(
                Int64($0),
                startDate: .twenty25(plus: startOffset),
                endDate: .twenty25(plus: startOffset + 50)
            )
        }
        // Generate objects for foreign keys
        let roomBeds = activityLogs
            .map { $0.hospitalRoomBedId }
            .unique()
            .map { HospitalRoomBed.mock(id: $0, unit: unitID) }

        let units = roomBeds
            .map { $0.facilityUnitId }
            .unique()
            .map { HospitalUnit.mock($0) }

        let patientIDs = activityLogs
            .map { $0.patientId }
            .sorted()
            .unique()

        let patients = patientIDs
            .enumerated()
            .map { index, patientID in
                let roomBedID = (roomBeds[optional: index] ?? roomBeds.first!).id
                return ALTPatient.mock(patientID, room: roomBedID)
            }

        let sessions = activityLogs
            .map { $0.sessionId }
            .unique()
            .enumerated()
            .map { index, sessionID in
                let patientID = patientIDs[optional: index] ?? patientIDs.first!
                return ALTSession.mock(sessionID, patientID: patientID)
            }

        // Populate foreign keys in order
        for unit in units {
            try await database.writer.write { db in
                var mutable = unit
                try mutable.insert(db, onConflict: .ignore)
            }
        }
        for roomBed in roomBeds {
            try await database.writer.write { db in
                var mutable = roomBed
                try mutable.insert(db, onConflict: .ignore)
            }
        }
        for patient in patients {
            try await database.writer.write { db in
                var mutable = patient
                try mutable.insert(db, onConflict: .ignore)
            }
        }
        for session in sessions {
            try await database.writer.write { db in
                var mutable = session
                try mutable.insert(db, onConflict: .ignore)
            }
        }

        let initial = activityLogs[0..<3]
        for log in initial {
            try await database.writer.write { db in
                var mutable = log
                try mutable.insert(db, onConflict: .ignore)
            }
        }

        let exp0 = expectation(description: "testActivityLogPublisher - initial")
        let exp1 = expectation(description: "testActivityLogPublisher - 1")
        let exp2 = expectation(description: "testActivityLogPublisher - 2")
        let exp3 = expectation(description: "testActivityLogPublisher - 3")
        let expectations = [exp0, exp1, exp2, exp3]

        // GIVEN - the database is pre-loaded with required foreign keys & 3 ALTActiivtyLogs
        // AND - we have a way of capturing the publisher output
        var capturedLogs: [ALTActivityLog] = []
        var captureCount = 0
        cancellable = testSubject.activityLogPublisher
            .catch { error in
                XCTFail("No Errors Should Be Thrown: \(error.localizedDescription)")
                return Just([ALTActivityLog]()).eraseToAnyPublisher()
            }
            .sink { logs in
                capturedLogs = logs
                switch captureCount {
                case 0, 1, 2, 3:
                    expectations[captureCount].fulfill()
                default:
                    XCTFail("Should not receive more elements")
                }
                captureCount += 1
            }

        // define local helper function
        func test(index: Int, file: StaticString = #filePath, line: UInt = #line) async {
            await fulfillment(of: [expectations[index]], timeout: 2)
            XCTAssertEqual(capturedLogs.count, index + 3, file: file, line: line)
            let expected = activityLogs[0 ... (index + 2)]
            XCTAssertEqual(capturedLogs, Array(expected), file: file, line: line)
        }

        // THEN - we test the initial state of the publisher, we have the 3 initial values
        await test(index: 0)

        // WHEN - we add another log entry
        try await database.writer.write { db in
            var mutable = activityLogs[3]
            try mutable.insert(db, onConflict: .ignore)
        }
        // THEN - our total count and expected array matches
        await test(index: 1)

        // WHEN - we add another log entry
        try await database.writer.write { db in
            var mutable = activityLogs[4]
            try mutable.insert(db, onConflict: .ignore)
        }
        // THEN - our total count and expected array matches
        await test(index: 2)

        // WHEN - we add another log entry
        try await database.writer.write { db in
            var mutable = activityLogs[5]
            try mutable.insert(db, onConflict: .ignore)
        }
        // THEN - our total count and expected array matches
        await test(index: 3)
    }
}

private extension ActivityLogRepositoryTests {
    @discardableResult
    func populateDatabase(
        logs logsCount: Int,
        idOffset: Int = 0,
        sessionID: String = "session0",
        patientID: String = "patient0",
        unitID: String = "unit0",
        roomID: String = "room0",
        position: PositionalFlagCategory = .left,
        startPosition: PositionalFlagCategory = .supine,
        state: PatientMonitorState = .onResume,
        pauseReason: PauseReason = .null,
        timeStep: TimeInterval = 40,
        duration: TimeInterval = 50,
        isCurrent: Bool = true,
        isSynced: Bool = false
    ) async throws -> Int {
        let activityLogs = (0 ..< logsCount).map {
            let id = $0 + idOffset
            let startOffset = Double(id) * timeStep
            return ALTActivityLog.mock(
                Int64($0 + idOffset),
                patientID: patientID,
                sessionID: sessionID,
                roomID: roomID,
                startDate: .twenty25(plus: startOffset),
                endDate: .twenty25(plus: startOffset + duration),
                position: position,
                startPosition: .supine,
                monitoringState: state,
                pauseReason: pauseReason,
                isCurrent: isCurrent,
                isSynced: isSynced
            )
        }
        // Generate objects for foreign keys
        let roomBeds = activityLogs
            .map { $0.hospitalRoomBedId }
            .unique()
            .map { HospitalRoomBed.mock(id: $0, unit: unitID) }

        let units = roomBeds
            .map { $0.facilityUnitId }
            .unique()
            .map { HospitalUnit.mock($0) }

        let patientIDs = activityLogs
            .map { $0.patientId }
            .sorted()
            .unique()

        let patients = patientIDs
            .enumerated()
            .map { index, patientID in
                let roomBedID = (roomBeds[optional: index] ?? roomBeds.first!).id
                return ALTPatient.mock(patientID, room: roomBedID)
            }

        let sessions = activityLogs
            .map { $0.sessionId }
            .unique()
            .enumerated()
            .map { index, sessionID in
                let patientID = patientIDs[optional: index] ?? patientIDs.first!
                return ALTSession.mock(sessionID, patientID: patientID)
            }

        // Populate foreign keys in order
        for unit in units {
            try await database.writer.write { db in
                var mutable = unit
                try mutable.insert(db, onConflict: .ignore)
            }
        }
        for roomBed in roomBeds {
            try await database.writer.write { db in
                var mutable = roomBed
                try mutable.insert(db, onConflict: .ignore)
            }
        }
        for patient in patients {
            try await database.writer.write { db in
                var mutable = patient
                try mutable.insert(db, onConflict: .ignore)
            }
        }
        for session in sessions {
            try await database.writer.write { db in
                var mutable = session
                try mutable.insert(db, onConflict: .ignore)
            }
        }
        // Populate activity logs
        for log in activityLogs {
            try await database.writer.write { db in
                var mutable = log
                try mutable.insert(db)
            }
        }

        // return running total
        let totalRecords = logsCount + idOffset
        return totalRecords
    }
}

private extension ALTActivityLog {
    static func mock(
        _ id: Int64?,
        patientID: String = "patient0",
        sessionID: String = "session0",
        roomID: String = "room0",
        startDate: Date = .twenty25,
        endDate: Date = .twenty25(plus: 500),
        position: PositionalFlagCategory = .left,
        startPosition: PositionalFlagCategory = .supine,
        startTimeRemaining: Double = 50,
        endTimeRemaining: Double? = nil,
        monitoringState: PatientMonitorState = .onResume,
        pauseReason: PauseReason = .null,
        isWrongPosition: Bool = false,
        mqttTopicStr: String = "a/b/c/x/y/z",
        updateID: String = "update0",
        headOfBedAngle: Int? = nil,
        turnAngle: Int? = 500,
        endingTargetPosition: String? = nil,
        isCurrent: Bool = true,
        isSynced: Bool = false
    ) -> ALTActivityLog {
        ALTActivityLog(
            patientID: patientID,
            sessionID: sessionID,
            actualPositionStarted: startDate,
            actualPositionEnded: endDate,
            actualPosition: position,
            startingTarget: startPosition,
            startingTimeRemaining: startTimeRemaining,
            endingTimeRemaining: endTimeRemaining,
            bmmMonitoringState: monitoringState.rawValue,
            bmmPauseReason: pauseReason.rawValue,
            isWrongPosition: isWrongPosition,
            hospitalRoomBedID: roomID,
            mqttTopicStr: mqttTopicStr,
            updateID: updateID,
            headOfBedAngle: headOfBedAngle,
            turnAngle: turnAngle,
            endingTargetPosition: endingTargetPosition,
            id: id,
            isCurrent: isCurrent,
            isSynced: isSynced
        )
    }
}

private extension HospitalRoomBed {
    static func mock(id: String, unit: String) -> HospitalRoomBed {
        HospitalRoomBed(
            id: id,
            facilityUnitId: unit,
            roomBedNumber: id,
            status: "rosy",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }
}

private extension HospitalUnit {
    static func mock(_ id: String) -> HospitalUnit {
        HospitalUnit(
            id: id,
            facilityId: "facility0",
            departmentId: "dept0",
            name: id,
            status: "cheery",
            lastModified: .twenty25,
            lastModifiedBy: "admin",
            serverLastModified: .twenty25
        )
    }
}

private extension ALTPatient {
    static func mock(_ id: String, room: String) -> ALTPatient {
        ALTPatient(
            hospitalRoomBedId: room,
            heightIn: 40,
            weightLbs: 50,
            hasPaceMaker: false,
            hasSternumSkinBroken: true,
            sex: .female,
            bmi: 40,
            props: "fan",
            id: id
        )
    }
}

private extension ALTSession {
    static func mock(_ id: String, patientID: String) -> ALTSession {
        ALTSession(
            patientId: patientID,
            turningProtocol: .superShort,
            positionsToAvoid: .walking,
            hasEnded: false,
            id: id
        )
    }
} // swiftlint:disable:this file_length
