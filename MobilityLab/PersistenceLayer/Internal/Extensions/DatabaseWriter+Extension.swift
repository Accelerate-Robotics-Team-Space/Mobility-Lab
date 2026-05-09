//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB

extension DatabaseWriter {
    // Reference: https://stackoverflow.com/questions/66461554/disabling-or-deferring-foreign-key-enforcement-with-grdb-for-database-migration
    func writeWithDeferredForeignKeys(_ updates: (Database) throws -> Void) throws {
        try writeWithoutTransaction { dataBase in
            // Disable foreign keys
            try dataBase.execute(sql: "PRAGMA foreign_keys = OFF")

            do {
                // Perform updates in a transaction
                try dataBase.inTransaction {
                    try updates(dataBase)

                    // Note to Nguyen: Comment above, but based on reference, you shouldnt. Keep this in mind
                    // if something related to db comes up
                    // Check foreign keys before commit
                    // if try Row.fetchOne(db, sql: "PRAGMA foreign_key_check") != nil {
                    //     throw DatabaseError(resultCode: .SQLITE_CONSTRAINT_FOREIGNKEY)
                    // }

                    return .commit
                }

                // Re-enable foreign keys
                try dataBase.execute(sql: "PRAGMA foreign_keys = ON")
            } catch {
                // Re-enable foreign keys and rethrow
                try dataBase.execute(sql: "PRAGMA foreign_keys = ON")
                throw error
            }
        }
    }
}
