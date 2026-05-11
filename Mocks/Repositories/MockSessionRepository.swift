//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM

final class MockSessionRepository: SessionRepositoryProtocol {
    // swiftlint:disable:next large_tuple
    typealias GetSessionHandlerInput = (ALTPatient, MqttRouter<DataFeedTopics>, TurningProtocol, [PositionalFlagCategory])

    var loadIdFromDBAsyncHandler: ((String) async -> ALTSession?)?
    var loadIdFromDBCompletionHandler: ((DispatchQueue, String, ((Result<ALTSession?, any Error>) -> Void)?) -> Void)?
    var loadAllFromDBAsyncHandler: (() async -> [ALTSession])?
    var loadAllFromDBCompletionHandler: ((DispatchQueue, ((Result<[ALTSession], any Error>) -> Void)?) -> Void)?
    var getLastSessionHandler: (() async -> ALTSession?)?
    var getSessionByIDHandler: ((String) async throws -> ALTSession)?
    var syncLoadAllFromDBHandler: (() -> [ALTSession])?
    var deleteAllFromDBHandler: ((((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteIdsFromDBHandler: (([String], ((Result<Int, any Error>) -> Void)?) -> Void)?
    var deleteFromDBHandler: ((ALTSession, ((Result<Bool, any Error>) -> Void)?) -> Void)?
    var saveToDBHandler: ((ALTSession, DispatchQueue, ((Result<ALTSession, any Error>) -> Void)?) -> Void)?
    var asyncSaveToDBHandler: ((ALTSession) async throws -> ALTSession)?
    var getSessionByPatientIDHandler: ((String, TurningProtocol, PositionalFlags) async -> ALTSession)?
    var syncSaveToDBHandler: ((ALTSession, DispatchQueue, ((Result<(), any Error>) -> Void)?) -> Void)?
    var saveAndFetchHandler: ((ALTSession) throws -> ALTSession)?
    var getSessionServiceResumeHandler: ((String, MqttRouter<DataFeedTopics>) async throws -> SessionService)?
    var getSessionServiceForPatientHandler: ((GetSessionHandlerInput) async throws -> SessionService)?

    func syncSaveAndFetch(_ obj: ALTSession) throws -> ALTSession {
        guard let saveAndFetchHandler else {
            fatalError("saveAndFetchHandler must be set")
        }
        return try saveAndFetchHandler(obj)
    }

    func loadIdFromDB(_ id: String) async -> ALTSession? {
        guard let loadIdFromDBAsyncHandler else {
            fatalError("loadIdFromDBAsyncHandler not set")
        }
        return await loadIdFromDBAsyncHandler(id)
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<ALTSession?, any Error>) -> Void)?) {
        guard let loadIdFromDBCompletionHandler else {
            fatalError("loadIdFromDBCompletionHandler not set")
        }
        loadIdFromDBCompletionHandler(onThread, id, result)
    }

    func loadAllFromDB() async -> [ALTSession] {
        guard let loadAllFromDBAsyncHandler else {
            fatalError("loadAllFromDBAsyncHandler not set")
        }
        return await loadAllFromDBAsyncHandler()
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[ALTSession], any Error>) -> Void)?) {
        guard let loadAllFromDBCompletionHandler else {
            fatalError("loadAllFromDBCompletionHandler not set")
        }
        loadAllFromDBCompletionHandler(onThread, result)
    }

    func getLastSession() async -> ALTSession? {
        guard let getLastSessionHandler else {
            fatalError("getLastSessionHandler must be set")
        }
        return await getLastSessionHandler()
    }

    func getSession(withID id: String) async throws -> ALTSession {
        guard let getSessionByIDHandler else {
            fatalError("getSessionByIDHandler must be set")
        }
        return try await getSessionByIDHandler(id)
    }

    func syncLoadAllFromDB() -> [ALTSession] {
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

    func deleteFromDB(_ obj: ALTSession, result: ((Result<Bool, any Error>) -> Void)?) {
        guard let deleteFromDBHandler else {
            fatalError("deleteFromDBHandler must be set")
        }
        deleteFromDBHandler(obj, result)
    }

    func saveToDB(_ obj: ALTSession, onThread: DispatchQueue, result: ((Result<ALTSession, any Error>) -> Void)?) {
        guard let saveToDBHandler else {
            fatalError("saveToDBHandler must be set")
        }
        saveToDBHandler(obj, onThread, result)
    }

    func asyncSaveToDB(_ obj: ALTSession) async throws -> ALTSession {
        guard let asyncSaveToDBHandler else {
            fatalError("asyncSaveToDBHandler must be set")
        }
        return try await asyncSaveToDBHandler(obj)
    }

    func getSession(patientId: String, turningProtocol: TurningProtocol, positionsToAvoid: PositionalFlags) async -> ALTSession {
        guard let getSessionByPatientIDHandler else {
            fatalError("getSessionByPatientIDHandler not set")
        }
        return await getSessionByPatientIDHandler(patientId, turningProtocol, positionsToAvoid)
    }

    func syncSaveToDB(_ obj: ALTSession, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        guard let syncSaveToDBHandler else {
            fatalError("syncSaveToDBHandler must be set")
        }
        syncSaveToDBHandler(obj, onThread, result)
    }

    func getSessionService(resume sessionID: String, router: MqttRouter<DataFeedTopics>) async throws -> SessionService {
        guard let getSessionServiceResumeHandler else {
            fatalError("getSessionServiceResumeHandler must be set")
        }
        return try await getSessionServiceResumeHandler(sessionID, router)
    }

    func getSessionService(for patient: ALTPatient, router: MqttRouter<DataFeedTopics>, turningProto: TurningProtocol, posToAvoid: [PositionalFlagCategory]) async throws -> SessionService {
        guard let getSessionServiceForPatientHandler else {
            fatalError("getSessionServiceForPatientHandler must be set")
        }
        return try await getSessionServiceForPatientHandler((patient, router, turningProto, posToAvoid))
    }
}

final class NullSessionRepository: SessionRepositoryProtocol {
    func loadIdFromDB(_ id: String) async -> ALTSession? {
        fatalError("Null Service Should Not Be Used")
    }

    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<ALTSession?, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB() async -> [ALTSession] {
        fatalError("Null Service Should Not Be Used")
    }

    func getLastSession() async -> ALTSession? {
        fatalError("Null Service Should Not Be Used")
    }

    func getSession(withID id: String) async throws -> ALTSession {
        fatalError("Null Service Should Not Be Used")
    }

    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<[ALTSession], any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func syncLoadAllFromDB() -> [ALTSession] {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteAllFromDB(result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteIdsFromDB(_ ids: [String], result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func deleteFromDB(_ obj: ALTSession, result: ((Result<Bool, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func saveToDB(_ obj: ALTSession, onThread: DispatchQueue, result: ((Result<ALTSession, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func asyncSaveToDB(_ obj: ALTSession) async throws -> ALTSession {
        fatalError("Null Service Should Not Be Used")
    }

    func getSession(patientId: String, turningProtocol: TurningProtocol, positionsToAvoid: PositionalFlags) async -> ALTSession {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveToDB(_ obj: ALTSession, onThread: DispatchQueue, result: ((Result<(), any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func syncSaveAndFetch(_ obj: ALTSession) throws -> ALTSession {
        fatalError("Null Service Should Not Be Used")
    }

    func getSessionService(resume sessionID: String, router: MqttRouter<DataFeedTopics>) async throws -> SessionService {
        fatalError("Null Service Should Not Be Used")
    }

    func getSessionService(for patient: ALTPatient, router: MqttRouter<DataFeedTopics>, turningProto: TurningProtocol, posToAvoid: [PositionalFlagCategory]) async throws -> SessionService {
        fatalError("Null Service Should Not Be Used")
    }
}
