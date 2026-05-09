//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import Network
@testable import MobilityLab_BMM

class MockNetworkPathMonitor: NetworkPathMonitorProtocol {
    var statusUpdateHandler: ((NWPath.Status) -> Void)?
    var queueHandler: ((DispatchQueue) -> Void)?

    private(set) var isStarted = false
    private(set) var isStartCalled = false
    private(set) var isCancelCalled = false
    private(set) var currentNetworkStatus: NWPath.Status

    init(currentNetworkStatus: NWPath.Status = .unsatisfied) {
        self.currentNetworkStatus = currentNetworkStatus
    }

    func start(queue: DispatchQueue) {
        isStarted = true
        isStartCalled = true
        queueHandler?(queue)
        queue.async {
            self.statusUpdateHandler?(self.currentNetworkStatus)
        }
    }

    func cancel() {
        isStarted = false
        isCancelCalled = true
    }

    // Method to simulate network changes
    func simulate(status: NWPath.Status) {
        currentNetworkStatus = status
        statusUpdateHandler?(status)
    }
}
