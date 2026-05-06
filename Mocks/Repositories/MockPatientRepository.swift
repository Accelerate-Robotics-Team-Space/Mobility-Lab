//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockPatientRepository: PatientRepositoryProtocol {
    var updateLocationHandler: ((ALTPatient, PatientLocation) async -> ALTPatient)?
    var updateProfileHandler: ((String, ALTPatient.ProfileUpdate) async throws -> ALTPatient?)?
    var updatePropsHandler: ((ALTPatient, String) async -> ALTPatient)?
    var updateAltPatientIdHandler: ((ALTPatient, String) async -> ALTPatient)?
    var updateIsSyncedHandler: ((ALTPatient, Bool) async -> ALTPatient)?
    var latestPatientHandler: (() async throws -> ALTPatient?)?
    var pruneHandler: ((Int) -> Void)?
    var fetchNonSyncedHandler: ((Int) -> [ALTPatient])?
    var getPatientByIDHandler: ((String) async -> ALTPatient?)?
    var updateDetailsHandler: ((ALTPatient) async -> ALTPatient)?
    var loadAllFromDBHandler: ((DispatchQueue, ((Result<[ALTPatient], any Error>) -> Void)?) -> Void)?
    var syncLoadAllHandler: (() -> [ALTPatient])?
    var loadIdAsyncFromDBHandler: ((String) async -> ALTPatient?)?
    var loadIdCompletionFromDBHandler: ((DispatchQueue, String, ((Result<ALTPatient?, any Error>) -> Void)?) -> Void)?
    var loadAllFromDBAsyncHandler: (() async -> [ALTPatient])?
    var deleteAllFromDBHandler: ((((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteIdsFromDBHandler: (([String], ((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteFromDBHandler: ((ALTPatient, ((Result<Bool, any Error>) -> Void)?) -> Void)?
    var saveToDBHandler: ((ALTPatient, DispatchQueue, ((Result<ALTPatient, any Error>) -> Void)?) -> Void)?
    var asyncSaveToDBHandler: ((ALTPatient) async throws -> ALTPatient)?
    var syncSaveToDBHandler: ((ALTPatient, DispatchQueue, ((Result<(), any Error>) -> Void)?) -> Void)?
    var saveAndFetchHandler: ((ALTPatient) throws -> ALTPatient)?

    func syncSaveAndFetch(_ obj: ALTPatient) throws -> ALTPatient {
        guard let saveAndFetchHandler else {
            fatalError("saveAndFetchHandler must be set")
        }
        return try saveAndFetchHandler(obj)
    }

    func updateLocation(for patient: ALTPatient, to newLocation: PatientLocation) async -> ALTPatient {
        guard let updateLocationHandler else {
            fatalError("updateLocationHandler not set")
        }
        return await updateLocationHandler(patient, newLocation)
    }

    func update(patientID: String, profile: ALTPatient.ProfileUpdate) async throws -> ALTPatient? {
        guard let updateProfileHandler else {
            fatalError("updateProfileHandler not set")
        }
        return try await updateProfileHandler(patientID, profile)
    }

    func updateProps(for patient: ALTPatient, to props: String) async -> ALTPatient {
        guard let updatePropsHandler else {
            fatalError("updatePropsHandler not set")
        }
        return await updatePropsHandler(patient, props)
    }

    func updateAltPatientId(for patient: ALTPatient, to altId: String) async -> ALTPatient {
        guard let updateAltPatientIdHandler else {
            fatalError("updateAltPatientIdHandler not set")
        }
        return await updateAltPatientIdHandler(patient, altId)
    }

    func updateIsSynced(for patient: ALTPatient, to isSynced: Bool) async -> ALTPatient {
        guard let updateIsSyncedHandler else {
            fatalError("updateIsSyncedHandler not set")
        }
        return await updateIsSyncedHandler(patient, isSynced)
    }

    func latestPatient() async throws -> ALTPatient? {
        guard let latestPatientHandler else {
            fatalError("latestPatientHandler not set")
        }
        return try await latestPatientHandler()
    }

    func prune(remainingPatientCount: Int) {
        guard let pruneHandler else {
            fatalError("pruneHandler not set")
        }
        pruneHandler(remainingPatientCount)
    }

    func fetchNonSynced(withLimit: Int) -> [ALTPatient] {
        guard let fetchNonSyncedHandler else {
            fatalError("fetchNonSyncedHandler not set")
        }
        return fetchNonSyncedHandler(withLimit)
    }

    func getPatient(id: String) async -> ALTPatient? {
        guard let getPatientByIDHandler else {
            fatalError("getPatientByIDHandler must be set")
        }
        return await getPatientByIDHandler(id)
    }

    func updateDetails(_ patient: ALTPatient) async -> ALTPatient {
        guard let updateDetailsHandler else {
            fatalError("updateDetailsHandler must be set")
        }
        return await updateDetailsHandler(patient)
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[ALTPatient], any Error>) -> Void)?) {
        guard let loadAllFromDBHandler else {
            fatalError("loadAllFromDBHandler must be set")
        }
        loadAllFromDBHandler(onThread, result)
    }

    func syncLoadAllFromDB() -> [ALTPatient] {
        guard let syncLoadAllHandler else {
            fatalError("syncLoadAllHandler must be set")
        }
        return syncLoadAllHandler()
    }

    func loadIdFromDB(_ id: String) async -> ALTPatient? {
        guard let loadIdAsyncFromDBHandler else {
            fatalError("loadIdAsyncFromDBHandler must be set")
        }
        return await loadIdAsyncFromDBHandler(id)
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<ALTPatient?, any Error>) -> Void)?) {
        guard let loadIdCompletionFromDBHandler else {
            fatalError("loadIdCompletionFromDBHandler must be set")
        }
        loadIdCompletionFromDBHandler(onThread, id, result)
    }

    func loadAllFromDB() async -> [ALTPatient] {
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

    func deleteFromDB(_ obj: ALTPatient, result: ((Result<Bool, any Error>) -> Void)?) {
        guard let deleteFromDBHandler else {
            fatalError("deleteFromDBHandler must be set")
        }
        deleteFromDBHandler(obj, result)
    }

    func saveToDB(_ obj: ALTPatient, onThread: DispatchQueue, result: ((Result<ALTPatient, any Error>) -> Void)?) {
        guard let saveToDBHandler else {
            fatalError("saveToDBHandler must be set")
        }
        saveToDBHandler(obj, onThread, result)
    }

    func asyncSaveToDB(_ obj: ALTPatient) async throws -> ALTPatient {
        guard let asyncSaveToDBHandler else {
            fatalError("asyncSaveToDBHandler must be set")
        }
        return try await asyncSaveToDBHandler(obj)
    }

    func syncSaveToDB(_ obj: ALTPatient, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        guard let syncSaveToDBHandler else {
            fatalError("syncSaveToDBHandler must be set")
        }
        syncSaveToDBHandler(obj, onThread, result)
    }
}

final class NullPatientRepository: PatientRepositoryProtocol {
    func updateLocation(for patient: ALTPatient, to newLocation: PatientLocation) async -> ALTPatient {
        fatalError("Null Service Should Not Be Used")
    }

    func update(patientID: String, profile: ALTPatient.ProfileUpdate) async throws -> ALTPatient? {
        fatalError("Null Service Should Not Be Used")
    }

    func updateProps(for patient: ALTPatient, to props: String) async -> ALTPatient {
        fatalError("Null Service Should Not Be Used")
    }

    func updateAltPatientId(for patient: ALTPatient, to altId: String) async -> ALTPatient {
        fatalError("Null Service Should Not Be Used")
    }

    func updateIsSynced(for patient: ALTPatient, to isSynced: Bool) async -> ALTPatient {
        fatalError("Null Service Should Not Be Used")
    }

    func latestPatient() async throws -> ALTPatient? {
        fatalError("Null Service Should Not Be Used")
    }

    func prune(remainingPatientCount: Int) {
        fatalError("Null Service Should Not Be Used")
    }

    func fetchNonSynced(withLimit: Int) -> [ALTPatient] {
        fatalError("Null Service Should Not Be Used")
    }

    func getPatient(id: String) async -> ALTPatient? {
        fatalError("Null Service Should Not Be Used")
    }

    func updateDetails(_ patient: ALTPatient) async -> ALTPatient {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[ALTPatient], any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func syncLoadAllFromDB() -> [ALTPatient] {
        fatalError("Null Service Should Not Be Used")
    }

    func loadIdFromDB(_ id: String) async -> ALTPatient? {
        fatalError("Null Service Should Not Be Used")
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<ALTPatient?, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB() async -> [ALTPatient] {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteAllFromDB(result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteIdsFromDB(_ ids: [String], result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteFromDB(_ obj: ALTPatient, result: ((Result<Bool, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func saveToDB(_ obj: ALTPatient, onThread: DispatchQueue, result: ((Result<ALTPatient, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func asyncSaveToDB(_ obj: ALTPatient) async throws -> ALTPatient {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveToDB(_ obj: ALTPatient, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveAndFetch(_ obj: ALTPatient) throws -> ALTPatient {
        fatalError("Null Service Should Not Be Used")
    }
}
