//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import GRDB

extension GRDBStorageService {
    func migrate(all list: MigrationsList.Type, upTo migration: Migration.Type? = nil) throws {
        let migrator = makeDatabaseMigrator(list.self)
        if let migration = migration?.init() {
            try migrator.migrate(database, upTo: migration.identifier)
        } else {
            try migrator.migrate(database)
        }
    }

    private func makeDatabaseMigrator(_ migrationsList: MigrationsList.Type) -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        for type in migrationsList.migrations {
            let migration = type.init()
            migrator.registerMigration(migration.identifier, migrate: migration.perform(on:))
        }
        return migrator
    }
}
