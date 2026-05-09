//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB

typealias DataStorable = Identifiable & FetchableRecord & MutablePersistableRecord & Sendable

protocol DataStorableRepositoryProtocol {
    associatedtype Record = DataStorable & Sendable
    func loadAllFromDB(result: ((Result<[Record], any Error>) -> Void)?)
    func loadAllFromDB(onThread: DispatchQueue, result: ((Result<([Record]), any Error>) -> Void)?)
    func loadAllFromDB() async -> [Record]
    func loadIdFromDB(_ id: String, result: ((Result<Record?, any Error>) -> Void)?)
    func loadIdFromDB(onThread: DispatchQueue, _ id: String, result: ((Result<Record?, any Error>) -> Void)?)
    func loadIdFromDB(_ id: String) async -> Record?
    func syncLoadAllFromDB() -> [Record]
    func saveToDB(_ obj: Record)
    func saveToDB(_ obj: Record, onThread: DispatchQueue)
    func saveToDB(_ obj: Record, result: ((Result<(Record), Error>) -> Void)?)
    func saveToDB(_ obj: Record, onThread: DispatchQueue, result: ((Result<(Record), Error>) -> Void)?)
    @discardableResult func asyncSaveToDB(_ obj: Record) async throws -> Record
    func deleteFromDB(_ obj: Record)
    func deleteFromDB(_ obj: Record, result: ((Result<Bool, Error>) -> Void)?)
    func deleteIdsFromDB(_ ids: [String])
    func deleteIdsFromDB(_ ids: [String], result: ((Result<Int, Error>) -> Void)?)
    func deleteAllFromDB()
    func deleteAllFromDB(result: ((Result<Int, Error>) -> Void)?)
    func syncSaveToDB(_ obj: Record)
    func syncSaveToDB(_ obj: Record, onThread: DispatchQueue)
    func syncSaveToDB(_ obj: Record, result: ((Result<(), Error>) -> Void)?)
    func syncSaveToDB(_ obj: Record, onThread: DispatchQueue, result: ((Result<(), Error>) -> Void)?)
    func syncSaveAndFetch(_ obj: Record) throws -> Record
}

class DataStorableRepository<T: DataStorable>: DataStorableRepositoryProtocol {
    typealias Record = T

    let grdbService: any DatabaseService

    init(_ grdbService: any DatabaseService) {
        self.grdbService = grdbService
    }

    func loadAllFromDB(onThread: DispatchQueue = .main, result: ((Result<[T], Error>) -> Void)?) {
        let obj = T.self
        Task {
            do {
                let newItems = try await grdbService.read { dataStore in
                    try obj.fetchAll(dataStore)
                }
                result?(.success(newItems))
            } catch {
                logger.error(error.localizedDescription)
                result?(.failure(error))
            }
        }
    }

    func loadAllFromDB() async -> [T] {
        do {
            return try await grdbService.read { dataStore in
                try T.self.fetchAll(dataStore)
            }
        } catch {
            logger.error(error.localizedDescription)
            return []
        }
    }

    func loadIdFromDB(onThread: DispatchQueue = .main, _ id: String, result: ((Result<T?, Error>) -> Void)?) {
        Task {
            do {
                let obj = T.self
                let response = try await grdbService.read { dataStore in
                    let request = obj.filter(key: id)
                    return try obj.fetchOne(dataStore, request)
                }

                result?(.success(response))
            } catch {
                logger.error(error.localizedDescription)
                result?(.failure(error))
            }
        }
    }

    func loadIdFromDB(_ id: String) async -> T? {
        do {
            let obj = T.self
            return try await grdbService.read { dataStore in
                let request = obj.filter(key: id)
                return try obj.fetchOne(dataStore, request)
            }
        } catch {
            logger.error(error.localizedDescription)
            return nil
        }
    }

    func syncLoadAllFromDB() -> [T] {
        GRDBStorageService.queue.sync {
            do {
                return try grdbService.reader.read { dataStore in
                    try T.self.fetchAll(dataStore)
                }
            } catch {
                logger.error(error.localizedDescription)
                return []
            }
        }
    }

    func saveToDB(_ obj: T, onThread: DispatchQueue = .main, result: ((Result<(T), Error>) -> Void)? = nil) {
        Task {
            do {
                let value = try await grdbService.write { dataStore in
                    return try obj.saved(dataStore)
                }
                onThread.async {
                    result?(.success(value))
                }
            } catch let error as GRDB.RecordError {
                // RecordError is thrown by MutablePersistableRecord types when an update method could not find any row to update
                // RecordError is also thrown by FetchableRecord types when a find method does not find any record
                switch error {
                case let .recordNotFound(tableName, key):
                    logger.error("Record Save Error. Record Not Found in \(tableName), Key: \(key)")
                    Task {
                        do {
                            let updated: T? = try await grdbService.writer.write { dataStore in
                                return try obj.insertAndFetch(dataStore)
                            }
                            guard let unwrappedUpdated: T = updated else {
                                onThread.async {
                                    result?(.failure(error))
                                }
                                return
                            }
                            logger.info("Record Save Fixed. Record Inserted")
                            onThread.async {
                                result?(.success(unwrappedUpdated))
                            }
                        } catch {
                            logger.error("Record Save Error. Insert Failed")
                            onThread.async {
                                result?(.failure(error))
                            }
                        }
                    }
                }
            } catch let error as GRDB.DatabaseError {
                // Underlying SQL error
                if error.message?.hasPrefix("FOREIGN KEY constraint failed") == true {
                    logger.error("Record Save Database Error: Foreign Key Constraint Failure")
                } else {
                    logger.error("Record Save Database Error: \(error.message ?? error.localizedDescription). \(error)")
                }
                onThread.async {
                    result?(.failure(error))
                }
            } catch {
                logger.error(error.localizedDescription)
                onThread.async {
                    result?(.failure(error))
                }
            }
        }
    }

    func syncSaveToDB(_ obj: T, onThread: DispatchQueue = .main, result: ((Result<(), Error>) -> Void)? = nil) {
        do {
            var mutableObj = obj
            try grdbService.writer.write { dataStore in
                try mutableObj.save(dataStore)
            }
            onThread.async {
                result?(.success)
            }
        } catch let error as GRDB.RecordError {
            // RecordError is thrown by MutablePersistableRecord types when an update method could not find any row to update
            // RecordError is also thrown by FetchableRecord types when a find method does not find any record
            switch error {
            case let .recordNotFound(tableName, key):
                logger.error("Record Save Error. Record Not Found in \(tableName), Key: \(key)")
                do {
                    var mutableObj = obj
                    try grdbService.writer.write { dataStore in
                        try mutableObj.insert(dataStore)
                    }
                    onThread.async {
                        result?(.success(()))
                    }
                } catch {
                    logger.error("Record Save Error. Insert Failed")
                    onThread.async {
                        result?(.failure(error))
                    }
                }
            }
        } catch let error as GRDB.DatabaseError {
            // Underlying SQL error
            if error.message?.hasPrefix("FOREIGN KEY constraint failed") == true {
                logger.error("Record Save Database Error: Foreign Key Constraint Failure")
            } else {
                logger.error("Record Save Database Error: \(error.message ?? error.localizedDescription). \(error)")
            }
            onThread.async {
                result?(.failure(error))
            }
        } catch {
            logger.error(error.localizedDescription + ": \(self)")
            onThread.async {
                result?(.failure(error))
            }
        }
    }

    func syncSaveAndFetch(_ obj: T) throws -> T {
        do {
            let updated = try grdbService.writer.write { dataStore in
                try obj.saved(dataStore)
            }
            return updated
        } catch let error as GRDB.RecordError {
            // RecordError is thrown by MutablePersistableRecord types when an update method could not find any row to update
            // RecordError is also thrown by FetchableRecord types when a find method does not find any record
            switch error {
            case let .recordNotFound(tableName, key):
                do {
                    let updated = try grdbService.writer.write { dataStore in
                        try obj.inserted(dataStore)
                    }
                    return updated
                } catch {
                    logger.error("Record Save Error. Record Not Found in \(tableName), Key: \(key)")
                    throw error
                }
            }
        } catch let error as GRDB.DatabaseError {
            // Underlying SQL error
            if error.message?.hasPrefix("FOREIGN KEY constraint failed") == true {
                logger.error("Record Save Database Error: Foreign Key Constraint Failure")
            }
            throw error
        } catch {
            throw error
        }
    }

    @discardableResult
    func asyncSaveToDB(_ obj: T) async throws -> T {
        try await grdbService.write { dataStore in
            try obj.saved(dataStore)
        }
    }

    func deleteFromDB(_ obj: T, result: ((Result<Bool, Error>) -> Void)? = nil) {
        Task {
            do {
                let wasDeleted = try await grdbService.write { dataStore in
                    try obj.delete(dataStore)
                }
                result?(.success(wasDeleted))
            } catch {
                logger.error(error.localizedDescription)
                result?(.failure(error))
            }
        }
    }

    func deleteIdsFromDB(_ ids: [String], result: ((Result<Int, Error>) -> Void)? = nil) {
        Task {
            do {
                let numberOfDeletedRows = try await grdbService.write { store in
                    try T.self.deleteAll(store, keys: ids)
                }
                result?(.success(numberOfDeletedRows))
            } catch {
                logger.error(error.localizedDescription)
                result?(.failure(error))
            }
        }
    }

    func deleteAllFromDB(result: ((Result<Int, Error>) -> Void)? = nil) {
        Task {
            do {
                let numberOfDeletedRows = try await grdbService.write { dataStore in
                    try T.self.deleteAll(dataStore)
                }
                result?(.success(numberOfDeletedRows))
            } catch {
                logger.error(error.localizedDescription)
                result?(.failure(error))
            }
        }
    }
}

// MARK: - Protocol Default Conformance
extension DataStorableRepositoryProtocol {
    func loadIdFromDB(_ id: String, result: ((Result<Record?, any Error>) -> Void)?) {
        loadIdFromDB(onThread: .main, id, result: result)
    }

    func loadAllFromDB(result: ((Result<[Record], Error>) -> Void)?) {
        loadAllFromDB(onThread: .main, result: result)
    }

    func saveToDB(_ obj: Record) {
        saveToDB(obj, onThread: .main, result: nil)
    }

    func saveToDB(_ obj: Record, onThread: DispatchQueue) {
        saveToDB(obj, onThread: onThread, result: nil)
    }

    func saveToDB(_ obj: Record, result: ((Result<(Record), Error>) -> Void)?) {
        saveToDB(obj, onThread: .main, result: result)
    }

    func deleteFromDB(_ obj: Record) {
        deleteFromDB(obj, result: nil)
    }

    func deleteIdsFromDB(_ ids: [String]) {
        deleteIdsFromDB(ids, result: nil)
    }

    func deleteAllFromDB() {
        deleteAllFromDB(result: nil)
    }

    func syncSaveToDB(_ obj: Record) {
        syncSaveToDB(obj, onThread: .main, result: nil)
    }

    func syncSaveToDB(_ obj: Record, onThread: DispatchQueue) {
        syncSaveToDB(obj, onThread: onThread, result: nil)
    }

    func syncSaveToDB(_ obj: Record, result: ((Result<(), Error>) -> Void)?) {
        syncSaveToDB(obj, onThread: .main, result: result)
    }
}
