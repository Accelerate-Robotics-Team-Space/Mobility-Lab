//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockDatabaseManagementService: DatabaseManagementServiceProtocol {
    var startHandler: (() -> Void)?
    var resetTableHandler: (() throws -> Void)?
    var resetAllHandler: (() throws -> Void)?

    func start() {
        guard let startHandler else {
            fatalError("startHandler must be set")
        }
        startHandler()
    }
    
    func resetTable() throws {
        guard let resetTableHandler else {
            fatalError("resetTableHandler must be set")
        }
        try resetTableHandler()
    }
    
    func resetAll() throws {
        guard let resetAllHandler else {
            fatalError("resetAllHandler must be set")
        }
        try resetAllHandler()
    }
}

final class NullDatabaseManagementService: DatabaseManagementServiceProtocol {
    func start() {
        fatalError("Null Service Should Not Be Used")
    }

    func resetTable() throws {
        fatalError("Null Service Should Not Be Used")
    }

    func resetAll() throws {
        fatalError("Null Service Should Not Be Used")
    }
}
