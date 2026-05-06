//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import GRDB

protocol PatientRepositoryProtocol: DataStorableRepositoryProtocol where Record == ALTPatient {
    func updateLocation(for patient: ALTPatient, to newLocation: PatientLocation) async -> ALTPatient
    func update(patientID: String, profile: ALTPatient.ProfileUpdate) async throws -> ALTPatient?
    func updateProps(for patient: ALTPatient, to props: String) async -> ALTPatient
    func updateAltPatientId(for patient: ALTPatient, to altId: String) async -> ALTPatient
    func updateIsSynced(for patient: ALTPatient, to isSynced: Bool) async -> ALTPatient
    func latestPatient() async throws -> ALTPatient?
    func prune()
    func prune(remainingPatientCount: Int)
    func fetchNonSynced(withLimit: Int) -> [ALTPatient]
    func getPatient(id: String) async -> ALTPatient?
    func updateDetails(_ patient: ALTPatient) async -> ALTPatient
}

extension PatientRepositoryProtocol {
    func prune() {
        prune(remainingPatientCount: 10)
    }
}

extension Container {
    var patientRepository: Factory<any PatientRepositoryProtocol> {
        self { PatientRepository(resolve(\.databaseService)) }.cached
    }
}

final class PatientRepository: DataStorableRepository<ALTPatient>, PatientRepositoryProtocol {
    func updateLocation(for patient: ALTPatient, to newLocation: PatientLocation) async -> ALTPatient {
        guard newLocation.roomBed.id != patient.hospitalRoomBedId else {
            return patient
        }
        var mutablePatient = patient
        mutablePatient.update(roomBed: newLocation.roomBed)
        let updatedPatient = mutablePatient

        do {
            return try await grdbService.write { store in
                try store.execute(
                    sql: """
                         UPDATE altPatient
                         SET hospitalRoomBedId = ?
                         WHERE patientId = ?
                         """,
                    arguments: [newLocation.roomBed.id, patient.id]
                )
                return updatedPatient
            }
        } catch {
            logger.error(error.localizedDescription)
            return mutablePatient
        }
    }

    func update(patientID: String, profile: ALTPatient.ProfileUpdate) async throws -> ALTPatient? {
        let temp = try await grdbService.read { db in
            try ALTPatient.fetchOne(db, id: patientID)
        }
        guard let updated = temp?.updated(with: profile) else {
            return nil
        }
        try await grdbService.write { db in
            var mutable = updated
            try mutable.upsert(db)
        }
        return updated
    }

    func updateProps(for patient: ALTPatient, to props: String) async -> ALTPatient {
        await updateStored(patient, keyPath: \.props, to: props)
    }

    func updateAltPatientId(for patient: ALTPatient, to altId: String) async -> ALTPatient {
        await updateStored(patient, keyPath: \.altPatientId, to: altId)
    }

    func updateIsSynced(for patient: ALTPatient, to isSynced: Bool) async -> ALTPatient {
        await updateStored(patient, keyPath: \.isSynced, to: isSynced)
    }

    func latestPatient() async throws -> ALTPatient? {
        try await grdbService.read { db in
            try ALTPatient
                .order(Column("createdAt").desc)
                .limit(1)
                .fetchAll(db)
                .first
        }
    }

    func prune(remainingPatientCount: Int = 10) {
        Task {
            do {
                try await grdbService.write { store in
                    try store.execute(
                        sql: """
                             DELETE FROM altPatient
                             WHERE rowId NOT IN (
                              SELECT rowId
                              FROM (
                               SELECT rowId
                               FROM altPatient
                               ORDER BY rowId DESC
                               LIMIT ?
                              )
                             )
                             """,
                        arguments: [remainingPatientCount]
                    )
                }
            } catch {
                logger.error(error.localizedDescription)
            }
        }
    }

    func fetchNonSynced(withLimit: Int = 100) -> [ALTPatient] {
        do {
            var nonSynced: [ALTPatient] = []
            try GRDBStorageService.queue.sync {
                try grdbService.reader.read { store in
                    nonSynced = try ALTPatient.fetchAll(
                        store,
                        sql: """
                             SELECT p.*
                             FROM altPatient p
                             WHERE p.isSynced = FALSE
                             LIMIT ?
                             """,
                        arguments: [withLimit]
                    )
                }
            }
            return nonSynced
        } catch {
            logger.error(error.localizedDescription)
            return []
        }
    }

    func getPatient(id: String) async -> ALTPatient? {
        let patient = try? await grdbService.read { store in
            return try? ALTPatient.fetchOne(
                store,
                sql: """
                SELECT p.*
                FROM altPatient p
                WHERE patientId = ?
                """,
                arguments: [id]
            )
        }

        guard let patient else { return nil }

        return await updateDetails(patient)
    }

    func updateDetails(_ patient: ALTPatient) async -> ALTPatient {
        var patient = patient
        if let roomBed = await fetchRoomBed(hospitalRoomBedId: patient.hospitalRoomBedId) {
            patient.update(roomBed: roomBed)
        }
        patient.isSyncedToDB = await loadIdFromDB(patient.id)?.isSynced
        return patient
    }
}

private extension PatientRepository {
    func updateStored<T: Equatable & DatabaseValueConvertible>(
        _ patient: ALTPatient,
        keyPath: WritableKeyPath<ALTPatient, T>,
        to newValue: T
    ) async -> ALTPatient {
        guard patient.isUpdateNeeded(keyPath, to: newValue) else {
            return patient
        }
        let temp = patient.update(keyPath, to: newValue)
        let rowName = ALTPatient.rowName(keyPath)
        do {
            return try await grdbService.write { store in
                try store.execute(
                    sql: """
                    UPDATE altPatient
                    SET \(rowName) = ?
                    WHERE patientId = ?
                    """,
                    arguments: [newValue, temp.id])
                return temp
            }
        } catch {
            logger.error(error.localizedDescription)
            return temp
        }
    }

    func fetchRoomBed(hospitalRoomBedId: String) async -> HospitalRoomBed? {
        return try? await grdbService.read { store in
            let response: HospitalRoomBed? = try HospitalRoomBed.fetchOne(
                store,
                sql: """
                     SELECT h.*
                     FROM hospitalRoomBed h
                     WHERE id = ?
                     """,
                arguments: [hospitalRoomBedId]
            )
            return response
        }
    }
}

extension ALTSex: DatabaseValueConvertible { }

private extension ALTPatient {
    func isUpdateNeeded<T: Equatable>(_ keypath: KeyPath<ALTPatient, T>, to newValue: T) -> Bool {
        let existingValue = self[keyPath: keypath]
        return existingValue != newValue
    }

    func update<T>(_ keypath: WritableKeyPath<ALTPatient, T>, to newValue: T) -> ALTPatient {
        var mutable = self
        mutable[keyPath: keypath] = newValue
        return mutable
    }

    func updateIfNeeded<T: Equatable>(_ keyPath: WritableKeyPath<ALTPatient, T>, to newValue: T) -> ALTPatient {
        guard isUpdateNeeded(keyPath, to: newValue) else {
            return self
        }
        return update(keyPath, to: newValue)
    }

    static func rowName(_ keyPath: PartialKeyPath<ALTPatient>) -> String {
        let dict: [PartialKeyPath<ALTPatient>: String] = [
            \.id: ALTPatient.CodingKeys.id.rawValue,
            \.altPatientId: ALTPatient.CodingKeys.altPatientId.rawValue,
            \.hospitalRoomBedId: ALTPatient.CodingKeys.hospitalRoomBedId.rawValue,
            \.heightIn: ALTPatient.CodingKeys.heightIn.rawValue,
            \.weightLbs: ALTPatient.CodingKeys.weightLbs.rawValue,
            \.hasPaceMaker: ALTPatient.CodingKeys.hasPaceMaker.rawValue,
            \.hasSternumSkinBroken: ALTPatient.CodingKeys.hasSternumSkinBroken.rawValue,
            \.sex: ALTPatient.CodingKeys.sex.rawValue,
            \.bmi: ALTPatient.CodingKeys.bmi.rawValue,
            \.props: ALTPatient.CodingKeys.props.rawValue,
            \.createdAt: ALTPatient.CodingKeys.createdAt.rawValue,
            \.isSynced: ALTPatient.CodingKeys.isSynced.rawValue,
            \.sensorLocation: ALTPatient.CodingKeys.sensorLocation.rawValue,
        ]
        return dict[keyPath]! // swiftlint:disable:this force_unwrapping
    }
}
