//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockSyncManager: SyncManagerProtocol {
    var startHandler: (() -> Void)?
    var cleanupHandler: ((((Result<Int, any Error>) -> Void)?) -> Void)?

    func startSync() {
        guard let startHandler else {
            fatalError("startHandler must be set")
        }
        startHandler()
    }

    func cleanup(result: ((Result<Int, any Error>) -> Void)?) {
        guard let cleanupHandler else {
            fatalError("cleanupHandler must be set")
        }
        cleanupHandler(result)
    }
}

final class NullSyncManager: SyncManagerProtocol {
    func startSync() {
        fatalError("Null Service should not be used")
    }

    func cleanup(result: ((Result<Int, any Error>) -> Void)?) {
        fatalError("Null Service should not be used")
    }
}
