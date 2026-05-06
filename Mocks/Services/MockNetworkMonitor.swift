//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockNetworkMonitor: NetworkMonitorProtocol {
    var startHandler: (() -> Void)?
    var stopHandler: (() -> Void)?

    @Published var isConnected: Bool = false
    var isNetworkAvailable: Bool = false

    var isConnectedPublisher: Published<Bool>.Publisher {
        $isConnected
    }

    func start() {
        guard let startHandler else {
            fatalError("startHandler must be set")
        }
        startHandler()
    }
    
    func stop() {
        guard let stopHandler else {
            fatalError("stopHandler must be set")
        }
        stopHandler()
    }
}

final class NullNetworkMonitor: NetworkMonitorProtocol {
    var isNetworkAvailable: Bool {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var isConnected: Bool {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var isConnectedPublisher: Published<Bool>.Publisher {
        fatalError("Null Service Should Not Be Used")
    }

    func start() {
        fatalError("Null Service Should Not Be Used")
    }

    func stop() {
        fatalError("Null Service Should Not Be Used")
    }
}
