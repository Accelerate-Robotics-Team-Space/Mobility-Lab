// swiftlint:disable:this file_name
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import GRDB

final class AddWorkoutActivityFields_20260513: Migration {
    override func perform(on database: Database) throws {
        try database.alter(table: "workoutRecord") { table in
            table.add(column: "flightsClimbed", .double).notNull().defaults(to: 0)
            table.add(column: "cadence", .double).notNull().defaults(to: 0)
            table.add(column: "activityType", .text).notNull().defaults(to: "activity")
        }
    }
}
