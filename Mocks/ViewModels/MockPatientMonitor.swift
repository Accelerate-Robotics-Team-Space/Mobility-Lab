//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockPatientMonitor: PatientMonitorProtocol {
    var stopTimersHandler: (() -> Void)?
    var syncLogsHandler: (() async -> Void)?
    var endSessionHandler: (() async -> Void)?

    var syncingLogs: [String: LogState] = [:]

    func stopTimersAndUpdates() {
        guard let stopTimersHandler else {
            fatalError("stopTimersHandler must be set")
        }
        stopTimersHandler()
    }
    
    func syncLogs() async {
        guard let syncLogsHandler else {
            fatalError("syncLogsHandler must be set")
        }
        await syncLogsHandler()
    }

    func endSession() async {
        guard let endSessionHandler else {
            fatalError("endSessionHandler must be set")
        }
        await endSessionHandler()
    }
}

final class NullPatientMonitor: PatientMonitorProtocol {
    var syncingLogs: [String: LogState] = [:]

    func stopTimersAndUpdates() {
        fatalError("Null Service Should Not Be Used")
    }
    
    func syncLogs() async {
        fatalError("Null Service Should Not Be Used")
    }

    func endSession() async {
        fatalError("Null Service Should Not Be Used")
    }
}
