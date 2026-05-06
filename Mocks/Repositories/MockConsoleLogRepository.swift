//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockConsoleLogRepository: ConsoleLogRepositoryProtocol {
    var loadIdFromDBAsyncHandler: ((String) async -> ConsoleLogItem?)?
    var loadAllFromDBAsyncHandler: (() async -> [ConsoleLogItem])?
    var loadIdFromDBCompletionHandler: ((DispatchQueue, String, ((Result<ConsoleLogItem?, any Error>) -> Void)?) -> Void)?
    var loadAllFromDBCompletionHandler: ((DispatchQueue, ((Result<[ConsoleLogItem], any Error>) -> Void)?) -> Void)?
    var syncLoadAllFromDBHandler: (() -> [ConsoleLogItem])?
    var deleteAllFromDBHandler: ((((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteIdsFromDBHandler: (([String], ((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteFromDBHandler: ((ConsoleLogItem, ((Result<Bool, any Error>) -> Void)?) -> Void)?
    var saveToDBHandler: ((ConsoleLogItem, DispatchQueue, ((Result<ConsoleLogItem, any Error>) -> Void)?) -> Void)?
    var asyncSaveToDBHandler: ((ConsoleLogItem) async throws -> ConsoleLogItem)?
    var syncSaveToDBHandler: ((ConsoleLogItem, DispatchQueue, ((Result<(), any Error>) -> Void)?) -> Void)?
    var deleteOldItemsHandler: ((Int) -> Void)?
    var saveAndFetchHandler: ((ConsoleLogItem) throws -> ConsoleLogItem)?

    func syncSaveAndFetch(_ obj: ConsoleLogItem) throws -> ConsoleLogItem {
        guard let saveAndFetchHandler else {
            fatalError("saveAndFetchHandler must be set")
        }
        return try saveAndFetchHandler(obj)
    }

    func loadIdFromDB(_ id: String) async -> ConsoleLogItem? {
        guard let loadIdFromDBAsyncHandler else {
            fatalError("loadIdFromDBAsyncHandler must be set")
        }
        return await loadIdFromDBAsyncHandler(id)
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<ConsoleLogItem?, any Error>) -> Void)?) {
        guard let loadIdFromDBCompletionHandler else {
            fatalError("loadIdFromDBCompletionHandler must be set")
        }
        loadIdFromDBCompletionHandler(onThread, id, result)
    }

    func loadAllFromDB() async -> [ConsoleLogItem] {
        guard let loadAllFromDBAsyncHandler else {
            fatalError("loadAllFromDBAsyncHandler must be set")
        }
        return await loadAllFromDBAsyncHandler()
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[ConsoleLogItem], any Error>) -> Void)?) {
        guard let loadAllFromDBCompletionHandler else {
            fatalError("loadAllFromDBCompletionHandler must be set")
        }
        loadAllFromDBCompletionHandler(onThread, result)
    }

    func syncLoadAllFromDB() -> [ConsoleLogItem] {
        guard let syncLoadAllFromDBHandler else {
            fatalError("syncLoadAllFromDBHandler must be set")
        }
        return syncLoadAllFromDBHandler()
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

    func deleteFromDB(_ obj: ConsoleLogItem, result: ((Result<Bool, any Error>) -> Void)?) {
        guard let deleteFromDBHandler else {
            fatalError("deleteFromDBHandler must be set")
        }
        deleteFromDBHandler(obj, result)
    }

    func saveToDB(_ obj: ConsoleLogItem, onThread: DispatchQueue, result: ((Result<ConsoleLogItem, any Error>) -> Void)?) {
        guard let saveToDBHandler else {
            fatalError("saveToDBHandler must be set")
        }
        saveToDBHandler(obj, onThread, result)
    }

    func asyncSaveToDB(_ obj: ConsoleLogItem) async throws -> ConsoleLogItem {
        guard let asyncSaveToDBHandler else {
            fatalError("asyncSaveToDBHandler must be set")
        }
        return try await asyncSaveToDBHandler(obj)
    }

    func syncSaveToDB(_ obj: ConsoleLogItem, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        guard let syncSaveToDBHandler else {
            fatalError("syncSaveToDBHandler must be set")
        }
        syncSaveToDBHandler(obj, onThread, result)
    }

    func deleteOldItems(totalCount: Int) {
        guard let deleteOldItemsHandler else {
            fatalError("deleteOldItemsHandler must be set")
        }
        deleteOldItemsHandler(totalCount)
    }
}

final class NullConsoleLogRepository: ConsoleLogRepositoryProtocol {
    func loadIdFromDB(_ id: String) async -> ConsoleLogItem? {
        fatalError("Null Service Should Not Be Used")
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<ConsoleLogItem?, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB() async -> [ConsoleLogItem] {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[ConsoleLogItem], any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func syncLoadAllFromDB() -> [ConsoleLogItem] {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteAllFromDB(result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteIdsFromDB(_ ids: [String], result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteFromDB(_ obj: ConsoleLogItem, result: ((Result<Bool, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func saveToDB(_ obj: ConsoleLogItem, onThread: DispatchQueue, result: ((Result<ConsoleLogItem, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func asyncSaveToDB(_ obj: ConsoleLogItem) async throws -> ConsoleLogItem {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveToDB(_ obj: ConsoleLogItem, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteOldItems(totalCount: Int) {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveAndFetch(_ obj: ConsoleLogItem) throws -> ConsoleLogItem {
        fatalError("Null Service Should Not Be Used")
    }
}
