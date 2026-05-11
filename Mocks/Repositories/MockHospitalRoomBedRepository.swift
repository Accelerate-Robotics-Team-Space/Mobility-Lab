//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM

final class MockHospitalRoomBedRepository: HospitalRoomBedRepositoryProtocol {
    var loadIdFromDBAsyncHandler: ((String) async -> HospitalRoomBed?)?
    var loadAllFromDBAsyncHandler: (() async -> [HospitalRoomBed])?
    var loadIdFromDBCompletionHandler: ((DispatchQueue, String, ((Result<HospitalRoomBed?, any Error>) -> Void)?) -> Void)?
    var loadAllFromDBCompletionHandler: ((DispatchQueue, ((Result<[HospitalRoomBed], any Error>) -> Void)?) -> Void)?
    var getRoomBedForIdHandler: ((String) -> HospitalRoomBed?)?
    var syncLoadAllFromDBHandler: (() -> [HospitalRoomBed])?
    var deleteAllFromDBHandler: ((((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteIdsFromDBHandler: (([String], ((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteFromDBHandler: ((HospitalRoomBed, ((Result<Bool, any Error>) -> Void)?) -> Void)?
    var saveToDBHandler: ((HospitalRoomBed, DispatchQueue, ((Result<HospitalRoomBed, any Error>) -> Void)?) -> Void)?
    var asyncSaveToDBHandler: ((HospitalRoomBed) async throws -> HospitalRoomBed)?
    var syncSaveToDBHandler: ((HospitalRoomBed, DispatchQueue, ((Result<(), any Error>) -> Void)?) -> Void)?
    var saveAndFetchHandler: ((HospitalRoomBed) throws -> HospitalRoomBed)?

    func syncSaveAndFetch(_ obj: HospitalRoomBed) throws -> HospitalRoomBed {
        guard let saveAndFetchHandler else {
            fatalError("saveAndFetchHandler must be set")
        }
        return try saveAndFetchHandler(obj)
    }

    func loadIdFromDB(_ id: String) async -> HospitalRoomBed? {
        guard let loadIdFromDBAsyncHandler else {
            fatalError("loadIdFromDBAsyncHandler must be set")
        }
        return await loadIdFromDBAsyncHandler(id)
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<HospitalRoomBed?, any Error>) -> Void)?) {
        guard let loadIdFromDBCompletionHandler else {
            fatalError("loadIdFromDBCompletionHandler must be set")
        }
        loadIdFromDBCompletionHandler(onThread, id, result)
    }

    func loadAllFromDB() async -> [HospitalRoomBed] {
        guard let loadAllFromDBAsyncHandler else {
            fatalError("loadAllFromDBAsyncHandler must be set")
        }
        return await loadAllFromDBAsyncHandler()
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[HospitalRoomBed], any Error>) -> Void)?) {
        guard let loadAllFromDBCompletionHandler else {
            fatalError("loadAllFromDBCompletionHandler must be set")
        }
        loadAllFromDBCompletionHandler(onThread, result)
    }

    func getRoomBed(forId id: String) -> HospitalRoomBed? {
        guard let getRoomBedForIdHandler else {
            fatalError("getRoomBedForIdHandler must be set")
        }
        return getRoomBedForIdHandler(id)
    }

    func syncLoadAllFromDB() -> [HospitalRoomBed] {
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

    func deleteFromDB(_ obj: HospitalRoomBed, result: ((Result<Bool, any Error>) -> Void)?) {
        guard let deleteFromDBHandler else {
            fatalError("deleteFromDBHandler must be set")
        }
        deleteFromDBHandler(obj, result)
    }

    func saveToDB(_ obj: HospitalRoomBed, onThread: DispatchQueue, result: ((Result<HospitalRoomBed, any Error>) -> Void)?) {
        guard let saveToDBHandler else {
            fatalError("saveToDBHandler must be set")
        }
        saveToDBHandler(obj, onThread, result)
    }

    func asyncSaveToDB(_ obj: HospitalRoomBed) async throws -> HospitalRoomBed {
        guard let asyncSaveToDBHandler else {
            fatalError("asyncSaveToDBHandler must be set")
        }
        return try await asyncSaveToDBHandler(obj)
    }

    func syncSaveToDB(_ obj: HospitalRoomBed, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        guard let syncSaveToDBHandler else {
            fatalError("syncSaveToDBHandler must be set")
        }
        syncSaveToDBHandler(obj, onThread, result)
    }
}

final class NullHospitalRoomBedRepository: HospitalRoomBedRepositoryProtocol {
    func loadIdFromDB(_ id: String) async -> HospitalRoomBed? {
        fatalError("Null Service Should Not Be Used")
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<HospitalRoomBed?, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB() async -> [HospitalRoomBed] {
        fatalError("Null Service Should Not Be Used")
    }

    func getRoomBed(forId id: String) -> HospitalRoomBed? {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[HospitalRoomBed], any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func syncLoadAllFromDB() -> [HospitalRoomBed] {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteAllFromDB(result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteIdsFromDB(_ ids: [String], result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteFromDB(_ obj: HospitalRoomBed, result: ((Result<Bool, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func saveToDB(_ obj: HospitalRoomBed, onThread: DispatchQueue, result: ((Result<HospitalRoomBed, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func asyncSaveToDB(_ obj: HospitalRoomBed) async throws -> HospitalRoomBed {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveToDB(_ obj: HospitalRoomBed, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveAndFetch(_ obj: HospitalRoomBed) throws -> HospitalRoomBed {
        fatalError("Null Service Should Not Be Used")
    }
}
