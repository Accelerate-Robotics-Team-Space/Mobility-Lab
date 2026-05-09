//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM

final class MockHospitalUnitRepository: HospitalUnitRepositoryProtocol {
    // swiftlint:disable:next large_tuple
    typealias UpdateInput = ([HospitalUnit], [HospitalRoomBed], [HospitalUnitInfo], (any HospitalRoomBedRepositoryProtocol)?)

    var loadIdFromDBAsyncHandler: ((String) async -> HospitalUnit?)?
    var loadAllFromDBAsyncHandler: (() async -> [HospitalUnit])?
    var loadIdFromDBCompletionHandler: ((DispatchQueue, String, ((Result<HospitalUnit?, any Error>) -> Void)?) -> Void)?
    var loadAllFromDBCompletionHandler: ((DispatchQueue, ((Result<[HospitalUnit], any Error>) -> Void)?) -> Void)?
    var syncLoadAllFromDBHandler: (() -> [HospitalUnit])?
    var getAllHandler: (() async -> [HospitalUnitInfo])?
    var deleteAllFromDBHandler: ((((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteIdsFromDBHandler: (([String], ((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteFromDBHandler: ((HospitalUnit, ((Result<Bool, any Error>) -> Void)?) -> Void)?
    var saveToDBHandler: ((HospitalUnit, DispatchQueue, ((Result<HospitalUnit, any Error>) -> Void)?) -> Void)?
    var asyncSaveToDBHandler: ((HospitalUnit) async throws -> HospitalUnit)?
    var syncSaveToDBHandler: ((HospitalUnit, DispatchQueue, ((Result<(), any Error>) -> Void)?) -> Void)?
    var updateHandler: ((UpdateInput) -> (units: Diffs<HospitalUnit>, rooms: Diffs<HospitalRoomBed>))?
    var saveAndFetchHandler: ((HospitalUnit) throws -> HospitalUnit)?

    func syncSaveAndFetch(_ obj: HospitalUnit) throws -> HospitalUnit {
        guard let saveAndFetchHandler else {
            fatalError("saveAndFetchHandler must be set")
        }
        return try saveAndFetchHandler(obj)
    }

    func loadIdFromDB(_ id: String) async -> HospitalUnit? {
        guard let loadIdFromDBAsyncHandler else {
            fatalError("loadIdFromDBAsyncHandler must be set")
        }
        return await loadIdFromDBAsyncHandler(id)
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<HospitalUnit?, any Error>) -> Void)?) {
        guard let loadIdFromDBCompletionHandler else {
            fatalError("loadIdFromDBCompletionHandler must be set")
        }
        loadIdFromDBCompletionHandler(onThread, id, result)
    }

    func loadAllFromDB() async -> [HospitalUnit] {
        guard let loadAllFromDBAsyncHandler else {
            fatalError("loadAllFromDBAsyncHandler must be set")
        }
        return await loadAllFromDBAsyncHandler()
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[HospitalUnit], any Error>) -> Void)?) {
        guard let loadAllFromDBCompletionHandler else {
            fatalError("loadAllFromDBCompletionHandler must be set")
        }
        loadAllFromDBCompletionHandler(onThread, result)
    }

    func syncLoadAllFromDB() -> [HospitalUnit] {
        guard let syncLoadAllFromDBHandler else {
            fatalError("syncLoadAllFromDBHandler must be set")
        }
        return syncLoadAllFromDBHandler()
    }

    func getAll() async -> [HospitalUnitInfo] {
        guard let getAllHandler else {
            fatalError("getAllHandler must be set")
        }
        return await getAllHandler()
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

    func deleteFromDB(_ obj: HospitalUnit, result: ((Result<Bool, any Error>) -> Void)?) {
        guard let deleteFromDBHandler else {
            fatalError("deleteFromDBHandler must be set")
        }
        deleteFromDBHandler(obj, result)
    }

    func saveToDB(_ obj: HospitalUnit, onThread: DispatchQueue, result: ((Result<HospitalUnit, any Error>) -> Void)?) {
        guard let saveToDBHandler else {
            fatalError("saveToDBHandler must be set")
        }
        saveToDBHandler(obj, onThread, result)
    }

    func asyncSaveToDB(_ obj: HospitalUnit) async throws -> HospitalUnit {
        guard let asyncSaveToDBHandler else {
            fatalError("asyncSaveToDBHandler must be set")
        }
        return try await asyncSaveToDBHandler(obj)
    }

    func syncSaveToDB(_ obj: HospitalUnit, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        guard let syncSaveToDBHandler else {
            fatalError("syncSaveToDBHandler must be set")
        }
        syncSaveToDBHandler(obj, onThread, result)
    }

    func update(
        newUnits: [HospitalUnit],
        newRoomBeds: [HospitalRoomBed],
        existing: [HospitalUnitInfo],
        roomBedRepository: (any HospitalRoomBedRepositoryProtocol)?
    ) -> (units: Diffs<HospitalUnit>, rooms: Diffs<HospitalRoomBed>) {
        guard let updateHandler else {
            fatalError("updateHandler must be set")
        }
        return updateHandler((newUnits, newRoomBeds, existing, roomBedRepository))
    }
}

final class NullHospitalUnitRepository: HospitalUnitRepositoryProtocol {
    func getAll() async -> [HospitalUnitInfo] {
        fatalError("Null Service Should Not Be Used")
    }

    func loadIdFromDB(_ id: String) async -> HospitalUnit? {
        fatalError("Null Service Should Not Be Used")
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<HospitalUnit?, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB() async -> [HospitalUnit] {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[HospitalUnit], any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func syncLoadAllFromDB() -> [HospitalUnit] {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteAllFromDB(result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteIdsFromDB(_ ids: [String], result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteFromDB(_ obj: HospitalUnit, result: ((Result<Bool, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func saveToDB(_ obj: HospitalUnit, onThread: DispatchQueue, result: ((Result<HospitalUnit, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func asyncSaveToDB(_ obj: HospitalUnit) async throws -> HospitalUnit {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveToDB(_ obj: HospitalUnit, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func update(
        newUnits: [HospitalUnit],
        newRoomBeds: [HospitalRoomBed],
        existing: [HospitalUnitInfo],
        roomBedRepository: (any HospitalRoomBedRepositoryProtocol)?
    ) -> (units: Diffs<HospitalUnit>, rooms: Diffs<HospitalRoomBed>) {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveAndFetch(_ obj: HospitalUnit) throws -> HospitalUnit {
        fatalError("Null Service Should Not Be Used")
    }
}
