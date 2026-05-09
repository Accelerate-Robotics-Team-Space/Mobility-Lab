//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import GRDB

protocol DatabaseManagementServiceProtocol {
    /// Ensure database service instance is available
    func start()

    /// Deletes all entries from the following tables:
    /// `altActivityLog`, `altPatient`, `altSession`
    func resetTable() async throws

    /// Deletes all entries from the following tables: `altActivityLog`, `altPatient`, `altSession`, `hospitalRoomBed`, `hospitalUnit`, `revokedCertificate`, `sqlite_sequence`
    func resetAll() async throws
}

extension Container {
    var databaseManagementService: Factory<DatabaseManagementServiceProtocol> {
        self { DatabaseManagementService(resolve(\.databaseService)) }.cached
    }
}

final class DatabaseManagementService: DatabaseManagementServiceProtocol {
    private let grdbService: any DatabaseService

    init(_ database: any DatabaseService) {
        self.grdbService = database
    }

    /// Ensure database service instance is available
    func start() {
        // no op
    }

    /// Deletes all entries from the following tables:
    /// `altActivityLog`, `altPatient`, `altSession`
    func resetTable() async throws {
        try await grdbService.writeWithDeferredForeignKeys { store in
            try store.execute(sql: "DELETE FROM altActivityLog")
            try store.execute(sql: "DELETE FROM altPatient")
            try store.execute(sql: "DELETE FROM altSession")
        }
    }

    /// Deletes all entries from the following tables: `altActivityLog`, `altPatient`, `altSession`, `hospitalRoomBed`, `hospitalUnit`, `revokedCertificate`, `sqlite_sequence`
    func resetAll() async throws {
        try await grdbService.writeWithDeferredForeignKeys { store in
            try store.execute(sql: "DELETE FROM altActivityLog")
            try store.execute(sql: "DELETE FROM altPatient")
            try store.execute(sql: "DELETE FROM altSession")
            try store.execute(sql: "DELETE FROM hospitalRoomBed")
            try store.execute(sql: "DELETE FROM hospitalUnit")
            try store.execute(sql: "DELETE FROM revokedCertificate")
            try store.execute(sql: "DELETE FROM sqlite_sequence")
        }
    }
}
