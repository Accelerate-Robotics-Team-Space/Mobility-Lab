//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import MultipeerConnectivity
@testable import MobilityLab_BMM

final class FakeAdvertiser: NearbyServiceAdvertising {
    weak var delegate: MCNearbyServiceAdvertiserDelegate?
    private(set) var startCalls = 0
    private(set) var stopCalls = 0

    func startAdvertisingPeer() { startCalls += 1 }
    func stopAdvertisingPeer() { stopCalls += 1 }
}

final class MockNodeAdvertiser: NodeManagerProtocol {
    private(set) var logs: [String] = []

    func start() { }

    func addLog(_ logStr: String) {
        logs.append(logStr)
    }

    func transmit(_ transmitter: MultipeerTransmitter, result: @escaping (Result<(), Error>) -> Void) {
        result(.success(()))
    }
}
