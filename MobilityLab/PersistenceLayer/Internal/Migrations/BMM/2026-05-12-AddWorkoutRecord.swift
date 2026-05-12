// swiftlint:disable:this file_name
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import GRDB

final class AddWorkoutRecord_20260512: Migration {
    override func perform(on database: Database) throws {
        try database.create(table: "workoutRecord", options: .ifNotExists) { table in
            table.autoIncrementedPrimaryKey("id")
            table.column("startTime", .date).notNull()
            table.column("endTime", .date).notNull()
            table.column("steps", .double).notNull().defaults(to: 0)
            table.column("distance", .double).notNull().defaults(to: 0)
            table.column("heartRateAvg", .double).notNull().defaults(to: 0)
            table.column("heartRateMax", .double).notNull().defaults(to: 0)
            table.column("calories", .double).notNull().defaults(to: 0)
            table.column("spO2", .double).notNull().defaults(to: 0)
            table.column("wearLocation", .text).notNull().defaults(to: "wrist")
            table.column("isSynced", .boolean).notNull().defaults(to: false)
            table.column("healthKitWorkoutId", .text)
        }
    }
}
