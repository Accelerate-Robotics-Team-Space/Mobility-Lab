//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM

final class MockRevokedCertificateRepository: RevokedCertificateRepositoryProtocol {
    var loadIdFromDBAsyncHandler: ((String) async -> RevokedCertificate?)?
    var loadAllFromDBAsyncHandler: (() async -> [RevokedCertificate])?
    var loadIdFromDBCompletionHandler: ((DispatchQueue, String, ((Result<RevokedCertificate?, any Error>) -> Void)?) -> Void)?
    var loadAllFromDBCompletionHandler: ((DispatchQueue, ((Result<[RevokedCertificate], any Error>) -> Void)?) -> Void)?
    var syncLoadAllFromDBHandler: (() -> [RevokedCertificate])?
    var deleteAllFromDBHandler: ((((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteIdsFromDBHandler: (([String], ((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteFromDBHandler: ((RevokedCertificate, ((Result<Bool, any Error>) -> Void)?) -> Void)?
    var saveToDBHandler: ((RevokedCertificate, DispatchQueue, ((Result<RevokedCertificate, any Error>) -> Void)?) -> Void)?
    var asyncSaveToDBHandler: ((RevokedCertificate) async throws -> RevokedCertificate)?
    var syncSaveToDBHandler: ((RevokedCertificate, DispatchQueue, ((Result<(), any Error>) -> Void)?) -> Void)?
    var saveAndFetchHandler: ((RevokedCertificate) throws -> RevokedCertificate)?

    func syncSaveAndFetch(_ obj: RevokedCertificate) throws -> RevokedCertificate {
        guard let saveAndFetchHandler else {
            fatalError("saveAndFetchHandler must be set")
        }
        return try saveAndFetchHandler(obj)
    }

    func loadIdFromDB(_ id: String) async -> RevokedCertificate? {
        guard let loadIdFromDBAsyncHandler else {
            fatalError("loadIdFromDBAsyncHandler must be set")
        }
        return await loadIdFromDBAsyncHandler(id)
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<RevokedCertificate?, any Error>) -> Void)?) {
        guard let loadIdFromDBCompletionHandler else {
            fatalError("loadIdFromDBCompletionHandler must be set")
        }
        loadIdFromDBCompletionHandler(onThread, id, result)
    }

    func loadAllFromDB() async -> [RevokedCertificate] {
        guard let loadAllFromDBAsyncHandler else {
            fatalError("loadAllFromDBAsyncHandler must be set")
        }
        return await loadAllFromDBAsyncHandler()
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[RevokedCertificate], any Error>) -> Void)?) {
        guard let loadAllFromDBCompletionHandler else {
            fatalError("loadAllFromDBCompletionHandler must be set")
        }
        loadAllFromDBCompletionHandler(onThread, result)
    }

    func syncLoadAllFromDB() -> [RevokedCertificate] {
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

    func deleteFromDB(_ obj: RevokedCertificate, result: ((Result<Bool, any Error>) -> Void)?) {
        guard let deleteFromDBHandler else {
            fatalError("deleteFromDBHandler must be set")
        }
        deleteFromDBHandler(obj, result)
    }

    func saveToDB(_ obj: RevokedCertificate, onThread: DispatchQueue, result: ((Result<RevokedCertificate, any Error>) -> Void)?) {
        guard let saveToDBHandler else {
            fatalError("saveToDBHandler must be set")
        }
        saveToDBHandler(obj, onThread, result)
    }

    func asyncSaveToDB(_ obj: RevokedCertificate) async throws -> RevokedCertificate {
        guard let asyncSaveToDBHandler else {
            fatalError("asyncSaveToDBHandler must be set")
        }
        return try await asyncSaveToDBHandler(obj)
    }

    func syncSaveToDB(_ obj: RevokedCertificate, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        guard let syncSaveToDBHandler else {
            fatalError("syncSaveToDBHandler must be set")
        }
        syncSaveToDBHandler(obj, onThread, result)
    }
}

final class NullRevokedCertificateRepository: RevokedCertificateRepositoryProtocol {
    func loadIdFromDB(_ id: String) async -> RevokedCertificate? {
        fatalError("Null Service Should Not Be Used")
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<RevokedCertificate?, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB() async -> [RevokedCertificate] {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[RevokedCertificate], any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func syncLoadAllFromDB() -> [RevokedCertificate] {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteAllFromDB(result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteIdsFromDB(_ ids: [String], result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteFromDB(_ obj: RevokedCertificate, result: ((Result<Bool, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func saveToDB(_ obj: RevokedCertificate, onThread: DispatchQueue, result: ((Result<RevokedCertificate, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func asyncSaveToDB(_ obj: RevokedCertificate) async throws -> RevokedCertificate {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveToDB(_ obj: RevokedCertificate, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveAndFetch(_ obj: RevokedCertificate) throws -> RevokedCertificate {
        fatalError("Null Service Should Not Be Used")
    }
}
