//
//  DataStorable.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation
import GRDB

protocol DataStorable: Identifiable, FetchableRecord, MutablePersistableRecord {}

// MARK: - MutablePersistableRecord
extension DataStorable where Self: MutablePersistableRecord {
    mutating func saveToDB(onThread: DispatchQueue = .main, result: ((Result<(), Error>) -> Void)? = nil) {
        do {
            try DataStore.shared.writer?.write { dataStore in
                try self.save(dataStore)
            }
            
            onThread.async {
                result?(.success)
            }
        } catch {
            result?(.failure(error))
        }
    }
    
    mutating func deleteFromDB(result: ((Result<Bool, Error>) -> Void)? = nil) {
        do {
            var wasDeleted = false
            try DataStore.shared.writer?.write { dataStore in
                wasDeleted = try self.delete(dataStore)
            }
            
            result?(.success(wasDeleted))
        } catch {
            result?(.failure(error))
        }
    }
    
    static func deleteIdsFromDB(_ ids: [String], result: ((Result<Int, Error>) -> Void)? = nil) {
        do {
            var numberOfDeletedRows = 0
            
            try DataStore.shared.writer?.write { store in
                numberOfDeletedRows = try self.deleteAll(store, keys: ids)
            }
            
            result?(.success(numberOfDeletedRows))
        } catch {
            result?(.failure(error))
        }
    }
    
    static func deleteAllFromDB(result: ((Result<Int, Error>) -> Void)? = nil) {
        do {
            var numberOfDeletedRows = 0
            
            try DataStore.shared.writer?.write { dataStore in
                numberOfDeletedRows = try self.deleteAll(dataStore)
            }
            
            result?(.success(numberOfDeletedRows))
        } catch {
            result?(.failure(error))
        }
    }
}

// MARK: - FetchableRecord & MutablePersistableRecord
extension DataStorable where Self: FetchableRecord & MutablePersistableRecord {
    static func loadAllFromDB(result: ((Result<(), Error>) -> Void)? = nil) -> [Self] {
        do {
            let newItems = try DataStore.shared.writer?.read { dataStore in
                try self.fetchAll(dataStore)
            }
            
            result?(.success(()))
            return newItems ?? []
        } catch {
            result?(.failure(error))
            return []
        }
    }
    
    static func loadIdFromDB(_ id: String, result: ((Result<(), Error>) -> Void)? = nil) -> Self? {
        do {
            var loadedItem: Self?
            
            try DataStore.shared.writer?.read { dataStore in
                let request = self.filter(key: id)
                loadedItem = try self.fetchOne(dataStore, request)
            }
            
            result?(.success(()))
            return loadedItem
        } catch {
            result?(.failure(error))
            return nil
        }
    }
    
    static func dbItemPublisher() -> AnyPublisher<[Self], Error> {
        ValueObservation
            .tracking(self.all().fetchAll)
            .publisher(in: DataStore.shared.writer!)
            .eraseToAnyPublisher()
    }
}

extension DatabaseWriter {
    // Reference: https://stackoverflow.com/questions/66461554/disabling-or-deferring-foreign-key-enforcement-with-grdb-for-database-migration
    func writeWithDeferredForeignKeys(_ updates: (Database) throws -> Void) throws {
            try writeWithoutTransaction { database in
                // Disable foreign keys
                try database.execute(sql: "PRAGMA foreign_keys = OFF")

                do {
                    // Perform updates in a transaction
                    try database.inTransaction {
                        try updates(database)

                        // Note to Nguyen: Comment above, but based on reference, you shouldnt. Keep this in mind
                        // if something related to db comes up
                        // Check foreign keys before commit
                        // if try Row.fetchOne(db, sql: "PRAGMA foreign_key_check") != nil {
                        //     throw DatabaseError(resultCode: .SQLITE_CONSTRAINT_FOREIGNKEY)
                        // }
                        
                        return .commit
                    }
                    
                    // Re-enable foreign keys
                    try database.execute(sql: "PRAGMA foreign_keys = ON")
                } catch {
                    // Re-enable foreign keys and rethrow
                    try database.execute(sql: "PRAGMA foreign_keys = ON")
                    throw error
                }
            }
        }
}
