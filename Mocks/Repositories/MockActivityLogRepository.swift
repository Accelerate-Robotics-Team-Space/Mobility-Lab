//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM

final class MockActivityLogRepository: ActivityLogRepositoryProtocol {
    var fetchFromSessionHandler: ((String) async -> [ALTActivityLog])?
    var fetchSyncedNotInHandler: ((Int, String) async -> [ALTActivityLog])?
    var fetchSyncedHandler: ((Int) -> [ALTActivityLog])?
    var fetchNonSyncedWithLimitHandler: ((Int) -> [ALTActivityLog])?
    var fetchNonSyncedSessionHandler: ((String) async -> [ALTActivityLog])?
    var fetchAllUniqueDateHandler: ((String) async -> [String])?
    var fetchTotalDurationHandler: ((PositionalFlagCategory, String, String) async -> String)?
    var fetchTotalPauseDurationHandler: ((String, String) async -> String)?
    var fetchTotalDisconnectedDurationHandler: ((String, String) async -> String)?
    var fetchAllMonitoringActivityHandler: ((PositionalFlagCategory, String, String) async -> [ALTActivityLog])?
    var fetchAllPauseActivityHandler: ((String, String) async -> [ALTActivityLog])?
    var fetchAllDisconnectActivityHandler: ((String, String) async -> [ALTActivityLog])?
    var fetchDateStartEndHandler: ((String, String) async -> [Date])?
    var fetchTotalTimeNotComplyingHandler: ((String, String) async -> Double)?
    var fetchTotalTimeComplyingHandler: ((String, String) async -> Double)?
    var latestEndDateHandler: (() async -> Date?)?
    var endAllActivityLogsHandler: (() async -> Void)?
    var loadAllFromDBHandler: ((DispatchQueue, ((Result<[ALTActivityLog], any Error>) -> Void)?) -> Void)?
    var syncLoadAllHandler: (() -> [ALTActivityLog])?
    var loadIdAsyncFromDBHandler: ((String) async -> ALTActivityLog?)?
    var loadIdCompletionFromDBHandler: ((DispatchQueue, String, ((Result<ALTActivityLog?, any Error>) -> Void)?) -> Void)?
    var loadAllFromDBAsyncHandler: (() async -> [ALTActivityLog])?
    var deleteAllFromDBHandler: ((((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteIdsFromDBHandler: (([String], ((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteFromDBHandler: ((ALTActivityLog, ((Result<Bool, any Error>) -> Void)?) -> Void)?
    var saveToDBHandler: ((ALTActivityLog, DispatchQueue, ((Result<ALTActivityLog, any Error>) -> Void)?) -> Void)?
    var asyncSaveToDBHandler: ((ALTActivityLog) async throws -> ALTActivityLog)?
    var syncSaveToDBHandler: ((ALTActivityLog, DispatchQueue, ((Result<(), any Error>) -> Void)?) -> Void)?
    var resetAllIsCurrentHandler: (() async throws -> Void)?
    var deleteAllHandler: (() async throws -> Int)?
    var activityPublisherHandler: (() -> StorageValuePublisher<[ALTActivityLog]>)?
    var saveAndFetchHandler: ((ALTActivityLog) throws -> ALTActivityLog)?
    var withLastEndDateHandler: (() -> ALTActivityLog?)?

    func fetchFromSession(sessionId: String) async -> [ALTActivityLog] {
        guard let fetchFromSessionHandler else {
            fatalError("fetchFromSessionHandler must be set")
        }
        return await fetchFromSessionHandler(sessionId)
    }

    func fetchSynced(withLimit: Int, notIn sessionId: String) async -> [ALTActivityLog] {
        guard let fetchSyncedNotInHandler else {
            fatalError("fetchSyncedNotInHandler must be set")
        }
        return await fetchSyncedNotInHandler(withLimit, sessionId)
    }

    func fetchSynced(withLimit: Int) -> [ALTActivityLog] {
        guard let fetchSyncedHandler else {
            fatalError("fetchSyncedHandler must be set")
        }
        return fetchSyncedHandler(withLimit)
    }

    func fetchNonSynced(withLimit: Int) -> [ALTActivityLog] {
        guard let fetchNonSyncedWithLimitHandler else {
            fatalError("fetchNonSyncedWithLimitHandler must be set")
        }
        return fetchNonSyncedWithLimitHandler(withLimit)
    }

    func fetchNonSynced(sessionId: String) async -> [ALTActivityLog] {
        guard let fetchNonSyncedSessionHandler else {
            fatalError("fetchNonSyncedSessionHandler must be set")
        }
        return await fetchNonSyncedSessionHandler(sessionId)
    }

    func fetchAllUniqueDate(from sessionId: String) async -> [String] {
        guard let fetchAllUniqueDateHandler else {
            fatalError("fetchAllUniqueDateHandler must be set")
        }
        return await fetchAllUniqueDateHandler(sessionId)
    }

    func fetchTotalDuration(position: PositionalFlagCategory, from sessionId: String, date: String) async -> String {
        guard let fetchTotalDurationHandler else {
            fatalError("fetchTotalDurationHandler must be set")
        }
        return await fetchTotalDurationHandler(position, sessionId, date)
    }

    func fetchTotalPauseDuration(from sessionId: String, date: String) async -> String {
        guard let fetchTotalPauseDurationHandler else {
            fatalError("fetchTotalPauseDurationHandler must be set")
        }
        return await fetchTotalPauseDurationHandler(sessionId, date)
    }

    func fetchTotalDisconnectedDuration(from sessionId: String, date: String) async -> String {
        guard let fetchTotalDisconnectedDurationHandler else {
            fatalError("fetchTotalDisconnectedDurationHandler must be set")
        }
        return await fetchTotalDisconnectedDurationHandler(sessionId, date)
    }

    func fetchAllMonitoringActivity(
        position: PositionalFlagCategory,
        from sessionId: String,
        date: String
    ) async -> [ALTActivityLog] {
        guard let fetchAllMonitoringActivityHandler else {
            fatalError("fetchAllMonitoringActivityHandler must be set")
        }
        return await fetchAllMonitoringActivityHandler(position, sessionId, date)
    }

    func fetchAllPauseActivity(from sessionId: String, date: String) async -> [ALTActivityLog] {
        guard let fetchAllPauseActivityHandler else {
            fatalError("fetchAllPauseActivityHandler must be set")
        }
        return await fetchAllPauseActivityHandler(sessionId, date)
    }

    func fetchAllDisconnectActivity(from sessionId: String, date: String) async -> [ALTActivityLog] {
        guard let fetchAllDisconnectActivityHandler else {
            fatalError("fetchAllDisconnectActivityHandler must be set")
        }
        return await fetchAllDisconnectActivityHandler(sessionId, date)
    }

    func fetchDateStartEnd(from sessionId: String, date: String) async -> [Date] {
        guard let fetchDateStartEndHandler else {
            fatalError("fetchDateStartEndHandler must be set")
        }
        return await fetchDateStartEndHandler(sessionId, date)
    }

    func fetchTotalTimeNotComplying(from sessionId: String, date: String) async -> Double {
        guard let fetchTotalTimeNotComplyingHandler else {
            fatalError("fetchTotalTimeNotComplyingHandler must be set")
        }
        return await fetchTotalTimeNotComplyingHandler(sessionId, date)
    }

    func fetchTotalTimeNotComplyingNew(from sessionId: String, date: String) async -> Double {
        guard let fetchTotalTimeNotComplyingHandler else {
            fatalError("fetchTotalTimeNotComplyingHandler must be set")
        }
        return await fetchTotalTimeNotComplyingHandler(sessionId, date)
    }

    func fetchTotalTimeComplying(from sessionId: String, date: String) async -> Double {
        guard let fetchTotalTimeComplyingHandler else {
            fatalError("fetchTotalTimeComplyingHandler must be set")
        }
        return await fetchTotalTimeComplyingHandler(sessionId, date)
    }

    func latestEndDate() async -> Date? {
        guard let latestEndDateHandler else {
            fatalError("latestEndDateHandler must be set")
        }
        return await latestEndDateHandler()
    }

    func endAllActivityLog() async {
        guard let endAllActivityLogsHandler else {
            fatalError("endAllActivityLogsHandler must be set")
        }
        await endAllActivityLogsHandler()
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[ALTActivityLog], any Error>) -> Void)?) {
        guard let loadAllFromDBHandler else {
            fatalError("loadAllFromDBHandler must be set")
        }
        loadAllFromDBHandler(onThread, result)
    }

    func syncLoadAllFromDB() -> [ALTActivityLog] {
        guard let syncLoadAllHandler else {
            fatalError("syncLoadAllHandler must be set")
        }
        return syncLoadAllHandler()
    }

    func loadIdFromDB(_ id: String) async -> ALTActivityLog? {
        guard let loadIdAsyncFromDBHandler else {
            fatalError("loadIdAsyncFromDBHandler must be set")
        }
        return await loadIdAsyncFromDBHandler(id)
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<ALTActivityLog?, any Error>) -> Void)?) {
        guard let loadIdCompletionFromDBHandler else {
            fatalError("loadIdCompletionFromDBHandler must be set")
        }
        loadIdCompletionFromDBHandler(onThread, id, result)
    }

    func loadAllFromDB() async -> [ALTActivityLog] {
        guard let loadAllFromDBAsyncHandler else {
            fatalError("loadAllFromDBAsyncHandler must be set")
        }
        return await loadAllFromDBAsyncHandler()
    }

    func deleteAllFromDB(result: ((Result<Int, any Error>) -> Void)?) {
        guard let deleteAllFromDBHandler else {
            fatalError("deleteAllFromDBHandler must be set")
        }
        deleteAllFromDBHandler(result)
    }

    func deleteIdsFromDB(_ ids: [String], result: ((Result<Int, any Error>) -> Void)?) {
        guard let deleteIdsFromDBHandler else {
            fatalError("deleteIdsFromDBHandler must be set")
        }
        deleteIdsFromDBHandler(ids, result)
    }

    func deleteFromDB(_ obj: ALTActivityLog, result: ((Result<Bool, any Error>) -> Void)?) {
        guard let deleteFromDBHandler else {
            fatalError("deleteFromDBHandler must be set")
        }
        deleteFromDBHandler(obj, result)
    }

    func saveToDB(_ obj: ALTActivityLog, onThread: DispatchQueue, result: ((Result<ALTActivityLog, any Error>) -> Void)?) {
        guard let saveToDBHandler else {
            fatalError("saveToDBHandler must be set")
        }
        saveToDBHandler(obj, onThread, result)
    }

    func asyncSaveToDB(_ obj: ALTActivityLog) async throws -> ALTActivityLog {
        guard let asyncSaveToDBHandler else {
            fatalError("asyncSaveToDBHandler must be set")
        }
        return try await asyncSaveToDBHandler(obj)
    }

    func syncSaveToDB(_ obj: ALTActivityLog, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        guard let syncSaveToDBHandler else {
            fatalError("syncSaveToDBHandler must be set")
        }
        syncSaveToDBHandler(obj, onThread, result)
    }

    func resetAllIsCurrent() async throws {
        guard let resetAllIsCurrentHandler else {
            fatalError("resetAllIsCurrentHandler must be set")
        }
        try await resetAllIsCurrentHandler()
    }

    var activityLogPublisher: StorageValuePublisher<[ALTActivityLog]> {
        guard let activityPublisherHandler else {
            fatalError("activityPublisherHandler must be set")
        }
        return activityPublisherHandler()
    }

    func deleteAll() async throws -> Int {
        guard let deleteAllHandler else {
            fatalError("deleteAllHandler must be set")
        }
        return try await deleteAllHandler()
    }

    func withLatestEndDate() -> ALTActivityLog? {
        guard let withLastEndDateHandler else {
            fatalError("withLastEndDateHandler must be set")
        }
        return withLastEndDateHandler()
    }

    func syncSaveAndFetch(_ obj: ALTActivityLog) throws -> ALTActivityLog {
        guard let saveAndFetchHandler else {
            fatalError("saveAndFetchHandler must be set")
        }
        return try saveAndFetchHandler(obj)
    }
}

final class NullActivityLogRepository: ActivityLogRepositoryProtocol {
    func fetchFromSession(sessionId: String) async -> [ALTActivityLog] {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchSynced(withLimit: Int, notIn sessionId: String) async -> [ALTActivityLog] {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchSynced(withLimit: Int) -> [ALTActivityLog] {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchNonSynced(withLimit: Int) -> [ALTActivityLog] {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchNonSynced(sessionId: String) async -> [ALTActivityLog] {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchAllUniqueDate(from sessionId: String) async -> [String] {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchTotalDuration(position: PositionalFlagCategory, from sessionId: String, date: String) async -> String {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchTotalPauseDuration(from sessionId: String, date: String) async -> String {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchTotalDisconnectedDuration(from sessionId: String, date: String) async -> String {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchAllMonitoringActivity(
        position: PositionalFlagCategory,
        from sessionId: String,
        date: String
    ) async -> [ALTActivityLog] {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchAllPauseActivity(from sessionId: String, date: String) async -> [ALTActivityLog] {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchAllDisconnectActivity(from sessionId: String, date: String) async -> [ALTActivityLog] {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchDateStartEnd(from sessionId: String, date: String) async -> [Date] {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchTotalTimeNotComplying(from sessionId: String, date: String) async -> Double {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchTotalTimeNotComplyingNew(from sessionId: String, date: String) async -> Double {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchTotalTimeComplying(from sessionId: String, date: String) async -> Double {
        fatalError("Null Service Should Not Be Used")
    }

    func latestEndDate() async -> Date? {
        fatalError("Null Service Should Not Be Used")
    }

    func endAllActivityLog() async {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[ALTActivityLog], any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func syncLoadAllFromDB() -> [ALTActivityLog] {
        fatalError("Null Service Should Not Be Used")
    }

    func loadIdFromDB(_ id: String) async -> ALTActivityLog? {
        fatalError("Null Service Should Not Be Used")
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<ALTActivityLog?, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB() async -> [ALTActivityLog] {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteAllFromDB(result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteIdsFromDB(_ ids: [String], result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteFromDB(_ obj: ALTActivityLog, result: ((Result<Bool, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func saveToDB(_ obj: ALTActivityLog, onThread: DispatchQueue, result: ((Result<ALTActivityLog, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func asyncSaveToDB(_ obj: ALTActivityLog) async throws -> ALTActivityLog {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveToDB(_ obj: ALTActivityLog, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func resetAllIsCurrent() async throws {
        fatalError("Null Service Should Not Be Used")
    }

    var activityLogPublisher: StorageValuePublisher<[ALTActivityLog]> {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteAll() async throws -> Int {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveAndFetch(_ obj: ALTActivityLog) throws -> ALTActivityLog {
        fatalError("Null Service Should Not Be Used")
    }

    func withLatestEndDate() -> ALTActivityLog? {
        fatalError("Null Service Should Not Be Used")
    }
}
