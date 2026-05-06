//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB

extension GRDBStorageService {
    func writeWithDeferredForeignKeys(_ updates: @escaping (Database) throws -> Void) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            GRDBStorageService.queue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: PersistenceError.selfNotFound)
                    return
                }

                do {
                    try writer.writeWithDeferredForeignKeys(updates)
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func read<T>(_ value: @escaping (Database) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            GRDBStorageService.queue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: PersistenceError.selfNotFound)
                    return
                }

                do {
                    let result = try writer.read(value)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func write<T>(_ updates: @escaping (Database) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            GRDBStorageService.queue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: PersistenceError.selfNotFound)
                    return
                }

                do {
                    let result = try writer.write(updates)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetch<T: FetchableRecord>(sql: String, arguments: StatementArguments = StatementArguments()) throws -> [T] {
        try GRDBStorageService.queue.sync {
            return try reader.read { db in
                return try T.fetchAll(db, sql: sql, arguments: arguments)
            }
        }
    }

    func fetchOne<T: FetchableRecord>(sql: String, arguments: StatementArguments = StatementArguments()) throws -> T? {
        try GRDBStorageService.queue.sync {
            return try reader.read { db in
                return try T.fetchOne(db, sql: sql, arguments: arguments)
            }
        }
    }

    func fetch<T: FetchableRecord>(sql: String, arguments: StatementArguments = StatementArguments()) async throws -> [T] {
        try await read { store in
            try T.fetchAll(store, sql: sql, arguments: arguments)
        }
    }
}
