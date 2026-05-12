// swiftlint:disable:this file_name
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

enum Migrations: MigrationsList {
    // Ordered list of migrations
    static let migrations: [Migration.Type] = [
        Initial_20260203.self,
        AddWorkoutRecord_20260512.self,
    ]
}
