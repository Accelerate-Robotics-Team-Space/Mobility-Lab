//
//  DataStore.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation
import GRDB

class DataStore {
    static let shared = makeShared()
    let writer: DatabaseWriter?
    var reader: DatabaseReader {
        writer!
    }
    
    private var migrator: DatabaseMigrator {
        var newMigrator = DatabaseMigrator()
        
        #if DEV || QA
        // Speed up development by nuking the database when migrations change
        newMigrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        let allMigrations = ALTMigrations.shared.all
        let allKeys = allMigrations.keys.sorted {
            $0.compare($1, options: .numeric) == .orderedAscending
        }
//        logger.info("DB Migration order: \n\(allKeys.joined(separator: "\n"))\n")
        
        for key in allKeys {
            guard let migration = allMigrations[key] else { continue }
            newMigrator.registerMigration(key, migrate: migration)
        }
        
        return newMigrator
    }
    
    // MARK: - Init
    init(_ writer: DatabaseWriter) throws {
        self.writer = writer
        try migrator.migrate(writer)
    }
    
    init() {
        self.writer = nil
    }
    
    // MARK: - Util
    func setup() {}
}

// MARK: - Private
private extension DataStore {
    static func constructDataStoreUrl() throws -> URL {
        var url = try FileManager.default
            .url(for: .applicationSupportDirectory,
                 in: .userDomainMask,
                 appropriateFor: nil, create: true)
            .appendingPathComponent("db.sqlite")
        
        url.setTemporaryResourceValue(true, forKey: .isExcludedFromBackupKey)
        
        return url
    }
    
    static func makeShared() -> DataStore {
        do {
            let url = try constructDataStoreUrl()
            let dbPool = try DatabasePool(path: url.path)
            let newStore = try DataStore(dbPool)
            
            return newStore
        } catch {
            logger.error("Unresolved Data Store error: \(error)")
            
            #if DEV || QA
            fatalError("Unresolved Data Store error: \(error)")
            #else
            return DataStore()
            #endif
        }
    }
}
