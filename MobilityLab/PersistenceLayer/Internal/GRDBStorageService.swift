//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import GRDB

protocol StorableProtocol {
    func read<T>(_ value: @escaping (GRDB.Database) throws -> T) async throws -> T
    func write<T>(_ updates: @escaping (GRDB.Database) throws -> T) async throws -> T
    func writeWithDeferredForeignKeys(_ updates: @escaping (Database) throws -> Void) async throws
    func fetch<T: FetchableRecord>(sql: String, arguments: StatementArguments) throws -> [T]
    func fetch<T: FetchableRecord>(sql: String) throws -> [T]
    func fetchOne<T: FetchableRecord>(sql: String, arguments: StatementArguments) throws -> T?
    func fetchOne<T: FetchableRecord>(sql: String) throws -> T?
    func fetch<T: FetchableRecord>(sql: String, arguments: StatementArguments) async throws -> [T]
    func fetch<T: FetchableRecord>(sql: String) async throws -> [T]
}

extension StorableProtocol {
    func fetch<T: FetchableRecord>(sql: String) throws -> [T] {
        try fetch(sql: sql, arguments: StatementArguments())
    }

    func fetchOne<T: FetchableRecord>(sql: String) throws -> T? {
        try fetchOne(sql: sql, arguments: StatementArguments())
    }

    func fetch<T: FetchableRecord>(sql: String) async throws -> [T] {
        try await fetch(sql: sql, arguments: StatementArguments())
    }
}

protocol DatabaseService: StorableProtocol {
    var reader: DatabaseReader { get }
    var writer: DatabaseWriter { get }
}

protocol FlushDatabaseProtocol {
    func delete() throws
}

extension Container {
    /// This service should not be used directly in ViewModels
    /// This service should only be accessed by a Repository
    var databaseService: Factory<DatabaseService> {
        self { resolve(\.combinedDatabaseAndFlush) }
    }

    /// This service is intended as a debug utility only
    var databaseFlush: Factory<FlushDatabaseProtocol> {
        self { resolve(\.combinedDatabaseAndFlush) }
    }

    private var combinedDatabaseAndFlush: Factory<DatabaseService & FlushDatabaseProtocol> {
        self {
            do {
                let configuration = GRDBConfiguration(storageLocation: .onDisk(name: GRDBStorageService.databaseName))
                let fileService = self.fileService.resolve()
                return try GRDBStorageService(
                    fileService: fileService,
                    configuration: configuration,
                    migrationsList: Migrations.self
                )
            } catch {
                assertionFailure("Could not create database service: \(error.localizedDescription)")
                return NullDatabaseService()
            }
        }.cached
    }
}

final class GRDBStorageService: DatabaseService & FlushDatabaseProtocol & Sendable {
    enum MigrationTarget {
        case none
        case specific(Migration.Type)
        case latest
    }

    static let queue = DispatchQueue(label: "GRDBQueue", attributes: .concurrent)

    static let databaseName = "db"
    static let databaseExtension = "sqlite"
    let database: DatabaseReader & DatabaseWriter
    private let fileService: any FileServiceProtocol

    var reader: any DatabaseReader { database }
    var writer: any DatabaseWriter { database }

    init(
        fileService: any FileServiceProtocol,
        configuration: GRDBConfiguration,
        migrationsList: MigrationsList.Type = Migrations.self,
        migrationTarget: MigrationTarget = .latest
    ) throws {
        self.fileService = fileService

        switch configuration.storageLocation {
        case .inMemory:
            self.database = try DatabaseQueue(configuration: configuration.makeGRDBConfiguration())
        case .onDisk:
            let appSupportURL = try fileService.url(
                for: .applicationSupport,
                in: .userDomain
            )

            var databaseURL = appSupportURL
                .appendingPathComponent(configuration.storageLocation.databaseName)
                .appendingPathExtension(GRDBStorageService.databaseExtension)

            databaseURL.setTemporaryResourceValue(true, forKey: .isExcludedFromBackupKey)

            let databasePath = databaseURL.absoluteURL.standardized.path(percentEncoded: false)

            self.database = try DatabasePool(path: databasePath, configuration: configuration.makeGRDBConfiguration())
        }
        try migrate(to: migrationTarget, using: migrationsList)
    }

    private func migrate(
        to migrationTarget: MigrationTarget = .latest,
        using migrationsList: MigrationsList.Type = Migrations.self
    ) throws {
        switch migrationTarget {
        case .none: break
        case .specific(let target): try migrate(all: migrationsList, upTo: target)
        case .latest: try migrate(all: migrationsList)
        }
    }

    func delete() throws {
        try delete(using: Migrations.self)
    }

    func delete(using migrationsList: MigrationsList.Type) throws {
        try database.erase()
        try migrate(using: migrationsList)
    }
}

final class NullDatabaseService: DatabaseService & FlushDatabaseProtocol & Sendable {
    let database = try! DatabaseQueue(configuration: Configuration()) // swiftlint:disable:this force_try

    init() {
        assertionFailure("Null Database Service Created")
    }

    var reader: any DatabaseReader { database }
    var writer: any DatabaseWriter { database }
    func delete() throws { /* no op */ }
    func read<T>(_ value: @escaping (GRDB.Database) throws -> T) async throws -> T {
        fatalError("Null Database Service Created")
    }

    func write<T>(_ updates: @escaping (GRDB.Database) throws -> T) async throws -> T {
        fatalError("Null Database Service Created")
    }

    func writeWithDeferredForeignKeys(_ updates: @escaping (GRDB.Database) throws -> Void) async throws {
        fatalError("Null Database Service Created")
    }

    func fetchOne<T: FetchableRecord>(sql: String, arguments: StatementArguments) throws -> T? {
        fatalError("Null Database Service Created")
    }

    func fetch<T: FetchableRecord>(sql: String, arguments: StatementArguments) throws -> [T] {
        fatalError("Null Database Service Created")
    }
}
