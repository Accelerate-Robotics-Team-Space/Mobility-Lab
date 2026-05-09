//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import GRDB

protocol SessionRepositoryProtocol: DataStorableRepositoryProtocol where Record == ALTSession {
    func getLastSession() async -> ALTSession?
    func getSession(withID id: String) async throws -> ALTSession
    func getSession(patientId: String, turningProtocol: TurningProtocol, positionsToAvoid: PositionalFlags) async -> ALTSession
    func getSessionService(resume sessionID: String, router: MqttRouter<DataFeedTopics>) async throws -> SessionService
    func getSessionService(
        for patient: ALTPatient,
        router: MqttRouter<DataFeedTopics>,
        turningProto: TurningProtocol,
        posToAvoid: [PositionalFlagCategory]
    ) async throws -> SessionService
}

extension Container {
    var sessionRepository: Factory<any SessionRepositoryProtocol> {
        self {
            SessionRepository(
                grdbService: resolve(\.databaseService),
                patientRepository: resolve(\.patientRepository)
            )
        }.cached
    }
}

final class SessionRepository: DataStorableRepository<ALTSession>, SessionRepositoryProtocol {
    private let patientRepository: any PatientRepositoryProtocol

    init(grdbService: any DatabaseService, patientRepository: any PatientRepositoryProtocol) {
        self.patientRepository = patientRepository
        super.init(grdbService)
    }

    func getLastSession() async -> ALTSession? {
        do {
            let session = try await grdbService.read { store in
                let lastSession = try ALTSession.fetchOne(
                    store,
                    sql: """
                         SELECT s.*
                         FROM altSession s
                         ORDER BY hasEnded ASC
                         LIMIT 1
                         """
                )
                guard let lastSession else {
                    throw PersistenceError.noElementFound("SessionRepository.getLastSession")
                }
                return lastSession
            }

            return await updateSessionWithPatient(session)
        } catch {
            logger.error(error.localizedDescription)
            return nil
        }
    }

    func getSession(withID id: String) async throws -> ALTSession {
        let session = try await grdbService.read { store in
            return try ALTSession.fetchOne(
                store,
                sql: """
                     SELECT s.*
                     FROM altSession s
                     WHERE sessionId = ?
                     """,
                arguments: [id]
            )
        }

        guard let session else {
            throw PersistenceError.noElementFound("SessionRepository.getSession(withID:)")
        }

        return await updateSessionWithPatient(session)
    }

    func getSession(patientId: String, turningProtocol: TurningProtocol, positionsToAvoid: PositionalFlags) async -> ALTSession {
        let session = ALTSession(patientId: patientId, turningProtocol: turningProtocol, positionsToAvoid: positionsToAvoid)
        return await updateSessionWithPatient(session)
    }

    func getSessionService(
        for patient: ALTPatient,
        router: MqttRouter<DataFeedTopics>,
        turningProto: TurningProtocol,
        posToAvoid: [PositionalFlagCategory]
    ) async throws -> SessionService {
        let flags: PositionalFlags = posToAvoid.map(\.flag).combine()
        let newSession = await self.getSession(
            patientId: patient.id,
            turningProtocol: turningProto,
            positionsToAvoid: flags
        )
        let sessionService = SessionService(
            currentSession: newSession,
            turningProto: turningProto,
            router: router,
            positionsToAvoid: Set(posToAvoid)
        )
        try await self.asyncSaveToDB(newSession)
        return sessionService
    }

    func getSessionService(
        resume sessionID: String,
        router: MqttRouter<DataFeedTopics>
    ) async throws -> SessionService {
        let session = try await self.getSession(withID: sessionID)
        let posToAvoid = session.patient?.posToAvoidFromProps() ?? []

        let sessionService = SessionService(
            currentSession: session,
            turningProto: session.turningProtocol,
            router: router,
            positionsToAvoid: Set(posToAvoid)
        )
        return sessionService
    }

    private func updateSessionWithPatient(_ session: ALTSession) async -> ALTSession {
        var session = session
        let patient = await patientRepository.getPatient(id: session.patientId)
        session.patient = patient
        return session
    }
}
