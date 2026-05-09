//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import GRDB

protocol ActivityLogRepositoryProtocol: DataStorableRepositoryProtocol where Record == ALTActivityLog {
    func fetchFromSession(sessionId: String) async -> [ALTActivityLog]
    func fetchSynced(withLimit: Int, notIn sessionId: String) async -> [ALTActivityLog]
    func fetchSynced(withLimit: Int) -> [ALTActivityLog]
    func fetchNonSynced(withLimit: Int) -> [ALTActivityLog]
    func fetchNonSynced(sessionId: String) async -> [ALTActivityLog]
    func fetchAllUniqueDate(from sessionId: String) async -> [String]
    func fetchTotalDuration(position: PositionalFlagCategory, from sessionId: String, date: String) async -> String
    func fetchTotalPauseDuration(from sessionId: String, date: String) async -> String
    func fetchTotalDisconnectedDuration(from sessionId: String, date: String) async -> String
    func fetchAllMonitoringActivity(position: PositionalFlagCategory, from sessionId: String, date: String) async -> [ALTActivityLog]
    func fetchAllPauseActivity(from sessionId: String, date: String) async -> [ALTActivityLog]
    func fetchAllDisconnectActivity(from sessionId: String, date: String) async -> [ALTActivityLog]
    func fetchDateStartEnd(from sessionId: String, date: String) async -> [Date]
    func fetchTotalTimeNotComplying(from sessionId: String, date: String) async -> Double
    func fetchTotalTimeNotComplyingNew(from sessionId: String, date: String) async -> Double
    func fetchTotalTimeComplying(from sessionId: String, date: String) async -> Double
    var activityLogPublisher: StorageValuePublisher<[ALTActivityLog]> { get }
    @discardableResult func deleteAll() async throws -> Int

    func withLatestEndDate() -> ALTActivityLog?
    func latestEndDate() async -> Date?
    func endAllActivityLog() async
    func resetAllIsCurrent() async throws
}

extension Container {
    var activityLogRepository: Factory<any ActivityLogRepositoryProtocol> {
        self { ActivityLogRepository(resolve(\.databaseService)) }.cached
    }
}

final class ActivityLogRepository: DataStorableRepository<ALTActivityLog>, ActivityLogRepositoryProtocol {
    private lazy var timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    var activityLogPublisher: StorageValuePublisher<[ALTActivityLog]> {
        GRDBStorageValuePublisher(grdbService.reader) { db in
            try ALTActivityLog.fetchAll(db)
        }
    }

    func fetchFromSession(sessionId: String) async -> [ALTActivityLog] {
        await fetch(
            sql: """
            SELECT alog.*
            FROM altActivityLog alog
            WHERE alog.sessionId = ?
            """,
            arguments: [sessionId]
        )
    }

    @discardableResult
    func deleteAll() async throws -> Int {
        try await grdbService.writer.write { db in
            try ALTActivityLog.deleteAll(db)
        }
    }

    func fetchSynced(withLimit: Int, notIn sessionId: String) async -> [ALTActivityLog] {
        await fetch(
            sql: """
            SELECT alog.*
            FROM altActivityLog alog
            WHERE alog.isSynced = TRUE
            AND alog.sessionId != ?
            LIMIT ?
            """,
            arguments: [sessionId, withLimit]
        )
    }

    func fetchSynced(withLimit: Int) -> [ALTActivityLog] {
        fetch(
            sql: """
                 SELECT alog.*
                 FROM altActivityLog alog
                 WHERE alog.isSynced = TRUE
                 LIMIT ?
                 """,
            arguments: [withLimit]
        )
    }

    func fetchNonSynced(withLimit: Int) -> [ALTActivityLog] {
        fetch(
            sql: """
                 SELECT alog.*
                 FROM altActivityLog alog
                 WHERE alog.isSynced = FALSE
                 LIMIT ?
                 """,
            arguments: [withLimit]
        )
    }

    func fetchNonSynced(sessionId: String) async -> [ALTActivityLog] {
        await fetch(
            sql: """
            SELECT alog.*
            FROM altActivityLog alog
            WHERE alog.isSynced = FALSE
            AND sessionId = ?
            """,
            arguments: [sessionId]
        )
    }

    func fetchAllUniqueDate(from sessionId: String) async -> [String] {
        do {
            let result = try await grdbService.read { store in
                var allUniqueDate: [String] = []
                let rows = try Row.fetchAll(
                    store,
                    sql: """
                    SELECT DISTINCT strftime('%Y-%m-%d', alog.actualPositionStarted) Result
                    FROM altActivityLog alog
                    WHERE sessionId = ?
                    ORDER BY Result ASC
                    """,
                    arguments: [sessionId]
                )
                rows.forEach({ allUniqueDate.append(($0.databaseValues.first?.databaseValue.description)!) })
                return allUniqueDate
            }
            return result
        } catch {
            logError(error: error)
            return []
        }
    }

    func fetchTotalDuration(position: PositionalFlagCategory, from sessionId: String, date: String) async -> String {
        do {
            let totalDuration = try await grdbService.read { store in
                let array = try ALTActivityLog.fetchAll(
                    store,
                    sql: """
                    SELECT alog.*
                    FROM altActivityLog alog
                    WHERE sessionId = ?
                    AND strftime('%Y-%m-%d', alog.actualPositionStarted) = ?
                    AND alog.actualPosition = ?
                    """,
                    arguments: [
                        sessionId,
                        date.replacingOccurrences(of: "\"", with: ""),
                        position.description,
                    ]
                )

                return array.map(\.duration).reduce(0.0, +)
            }
            return timeFormatter.string(from: totalDuration)!
        } catch {
            logError(error: error)
            return "N/A"
        }
    }

    func fetchTotalPauseDuration(from sessionId: String, date: String) async -> String {
        do {
            let totalDuration = try await grdbService.read { store in
                let array = try ALTActivityLog.fetchAll(
                    store,
                    sql: """
                    SELECT alog.*
                    FROM altActivityLog alog
                    WHERE sessionId = ?
                    AND strftime('%Y-%m-%d', alog.actualPositionStarted) = ?
                    AND bmmMonitoringState LIKE '%"onPause"%'
                    """,
                    arguments: [
                        sessionId,
                        date.replacingOccurrences(of: "\"", with: ""),
                    ]
                )
                return array.map(\.duration).reduce(0.0, +)
            }
            return timeFormatter.string(from: totalDuration)!
        } catch {
            logError(error: error)
            return "N/A"
        }
    }

    func fetchTotalDisconnectedDuration(from sessionId: String, date: String) async -> String {
        do {
            let totalDuration = try await grdbService.read { store in
                let array = try ALTActivityLog.fetchAll(
                    store,
                    sql: """
                    SELECT alog.*
                    FROM altActivityLog alog
                    WHERE sessionId = ?
                    AND strftime('%Y-%m-%d', alog.actualPositionStarted) = ?
                    AND bmmPauseReason LIKE '%"Wearable Disconnected"%'
                    """,
                    arguments: [
                        sessionId,
                        date.replacingOccurrences(of: "\"", with: ""),
                    ]
                )
                return array.map(\.duration).reduce(0.0, +)
            }
            return timeFormatter.string(from: totalDuration)!
        } catch {
            logger.error(error.localizedDescription)
            return "N/A"
        }
    }

    func fetchAllMonitoringActivity(position: PositionalFlagCategory, from sessionId: String, date: String) async -> [ALTActivityLog] {
        await fetch(
            sql: """
            SELECT * FROM altActivityLog alog
            WHERE actualPosition = ?
            AND strftime('%Y-%m-%d', alog.actualPositionStarted) = ?
            AND sessionId = ?
            AND bmmMonitoringState LIKE '%"onResume"%'
            ORDER BY actualPositionStarted ASC
            """,
            arguments: [
                position.description,
                date.replacingOccurrences(of: "\"", with: ""),
                sessionId,
            ]
        )
    }

    func fetchAllPauseActivity(from sessionId: String, date: String) async -> [ALTActivityLog] {
//        let conditions: [SQLSpecificExpressible] = [
//            Column("sessionId") == sessionId,
//            Column("bmmMonitoringState") == PatientMonitorState.onPause.rawValue,
//            strftime("%Y-%m-%d", Column("actualPositionStarted")) == date.replacingOccurrences(of: "\"", with: ""),
//        ]
//
//        let result0 = (try? await grdbService.read { db in
//            try ALTActivityLog
//                .filter(conditions.joined(operator: .and))
//                .order(Column("actualPositionStarted").asc)
//                .fetchAll(db)
//        }) ?? []

        let result1 = await fetch(
            sql: """
            SELECT * FROM altActivityLog alog
            WHERE bmmMonitoringState LIKE '%"onPause"%'
            AND strftime('%Y-%m-%d', alog.actualPositionStarted) = ?
            AND sessionId = ?
            ORDER BY actualPositionStarted ASC
            """,
            arguments: [
                date.replacingOccurrences(of: "\"", with: ""),
                sessionId,
            ]
        )
//        print("Fixed:")
//        print(result0)
//        print("\n\nOriginal:")
//        print(result1)
        return result1
    }

    func fetchAllDisconnectActivity(from sessionId: String, date: String) async -> [ALTActivityLog] {
        await fetch(
            sql: """
            SELECT * FROM altActivityLog alog
            WHERE bmmPauseReason LIKE '%"Wearable Disconnected"%'
            AND strftime('%Y-%m-%d', alog.actualPositionStarted) = ?
            AND sessionId = ?
            ORDER BY actualPositionStarted ASC
            """,
            arguments: [
                date.replacingOccurrences(of: "\"", with: ""),
                sessionId,
            ]
        )
    }

    func fetchDateStartEnd(from sessionId: String, date: String) async -> [Date] {
        do {
            let result = try await grdbService.read { store in
                var array: [Date] = []
                let rows = try Row.fetchAll(
                    store,
                    sql: """
                    SELECT alog.*
                    FROM altActivityLog alog
                    WHERE sessionId = ?
                    AND strftime('%Y-%m-%d', alog.actualPositionStarted) = ?
                    """,
                    arguments: [
                        sessionId,
                        date.replacingOccurrences(of: "\"", with: ""),
                    ]
                )

                guard let firstRow = rows.first, let lastRow = rows.last else {
                    return array
                }

                let start = try ALTActivityLog(row: firstRow)
                let end = try ALTActivityLog(row: lastRow)
                array.append(start.actualPositionStarted)
                array.append(end.actualPositionEnded)
                return array
            }
            return result
        } catch {
            logError(error: error)
            return []
        }
    }

    func fetchTotalTimeNotComplying(from sessionId: String, date: String) async -> Double {
        do {
            let totalDuration = try await grdbService.read { store in
                let array = try ALTActivityLog.fetchAll(
                    store,
                    sql: """
                    SELECT alog.*
                    FROM altActivityLog alog
                    WHERE actualPosition != startingTargetPosition
                    AND sessionId = ?
                    AND strftime('%Y-%m-%d', alog.actualPositionStarted) = ?
                    AND bmmMonitoringState LIKE '%"onResume"%'
                    """,
                    arguments: [
                        sessionId,
                        date.replacingOccurrences(of: "\"", with: ""),
                    ]
                )

                return array.map(\.duration).reduce(0.0, +)
            }
            return totalDuration
        } catch {
            logError(error: error)
            return 0.0
        }
    }

    func fetchTotalTimeNotComplyingNew(from sessionId: String, date: String) async -> Double {
        do {
            let conditions: [SQLSpecificExpressible] = [
                Column("actualPosition") != Column("startingTargetPosition"),
                Column("sessionId") == sessionId,
                strftime("%Y-%m-%d", Column("actualPositionStarted")) == date.replacingOccurrences(of: "\"", with: ""),
                Column("bmmMonitoringState").like("%\(PatientMonitorState.onResume.rawValue)%"),
            ]

            let logs = try await grdbService.read { db in
                try ALTActivityLog
                    .filter(conditions.joined(operator: .and))
                    .order(Column("actualPositionStarted").asc)
                    .fetchAll(db)
            }
            return logs.map(\.duration).reduce(0.0, +)
        } catch {
            logError(error: error)
            return 0.0
        }
    }

    func fetchTotalTimeComplying(from sessionId: String, date: String) async -> Double {
        do {
            let totalDuration = try await grdbService.read { store in
                let array = try ALTActivityLog.fetchAll(
                    store,
                    sql: """
                    SELECT alog.*
                    FROM altActivityLog alog
                    WHERE isWrongPosition == 0
                    AND sessionId = ?
                    AND strftime('%Y-%m-%d', alog.actualPositionStarted) = ?
                    AND bmmMonitoringState LIKE '%"onResume"%'
                    """,
                    arguments: [
                        sessionId,
                        date.replacingOccurrences(of: "\"", with: ""),
                    ]
                )

                return array.map(\.duration).reduce(0.0, +)
            }
            return totalDuration
        } catch {
            logError(error: error)
            return 0.0
        }
    }

    func latestEndDate() async -> Date? {
        try? await grdbService.read { db in
            try Date.fetchOne(
                db,
                sql: """
                     SELECT MAX(actualPositionEnded) FROM altActivityLog
                     """
            )
        }
    }

    func endAllActivityLog() async {
        do {
            try await grdbService.write { store in
                try store.execute(
                    sql: """
                    UPDATE altActivityLog
                    SET isSynced = TRUE
                    """,
                    arguments: []
                )
            }
        } catch {
            logError(error: error)
        }
    }

    func resetAllIsCurrent() async throws {
        try await grdbService.write { store in
            try store.execute(
                sql: """
                     UPDATE altActivityLog
                     SET isCurrent = false
                     WHERE isCurrent = true
                     """
            )
        }
    }

    func withLatestEndDate() -> ALTActivityLog? {
        fetchOne(
            sql: """
                 SELECT *
                 FROM altActivityLog
                 WHERE actualPositionEnded = (SELECT MAX(actualPositionEnded) FROM altActivityLog);
                 """
        )
    }

    // MARK: - Private Helpers

    private func fetch(sql: String, arguments: StatementArguments = StatementArguments()) async -> [ALTActivityLog] {
        do {
            return try await grdbService.fetch(sql: sql, arguments: arguments)
        } catch {
            logError(error: error)
            return []
        }
    }

    private func fetch<T: FetchableRecord>(sql: String, arguments: StatementArguments = StatementArguments()) -> [T] {
        do {
            return try grdbService.fetch(sql: sql, arguments: arguments)
        } catch {
            logError(error: error)
            return []
        }
    }

    private func fetchOne<T: FetchableRecord>(sql: String, arguments: StatementArguments = StatementArguments()) -> T? {
        do {
            return try grdbService.fetchOne(sql: sql, arguments: arguments)
        } catch {
            logError(error: error)
            return nil
        }
    }

    private func fetch(sql: String, arguments: StatementArguments = StatementArguments()) -> [ALTActivityLog] {
        do {
            return try grdbService.fetch(sql: sql, arguments: arguments)
        } catch {
            logError(error: error)
            return []
        }
    }

    private func logError(error: any Error) {
        logger.error(error.localizedDescription)
    }
}
