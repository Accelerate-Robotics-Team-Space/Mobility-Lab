//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB

/// usage expample:
/// ```
/// func fetchAllPauseActivity(from sessionId: String, date: String) async throws -> [ALTActivityLog] {
///        let conditions: [SQLSpecificExpressible] = [
///            Column("sessionId") == sessionId,
///            Column("bmmMonitoringState") == PatientMonitorState.onPause.rawValue,
///            strftime("%Y-%m-%d", Column("actualPositionStarted")) == date.replacingOccurrences(of: "\"", with: ""),
///        ]
///
///        return try await grdbService.reader.read { db in
///            try ALTActivityLog
///                .filter(conditions.joined(operator: .and))
///                .order(Column("actualPositionStarted").asc)
///                .fetchAll(db)
///        }
/// }
/// ```
func strftime(_ format: String, _ date: SQLSpecificExpressible) -> SQLExpression {
    SQL("STRFTIME(\(format), \(date))").sqlExpression
}
