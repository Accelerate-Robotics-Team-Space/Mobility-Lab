//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM

final class MockNodeManager: NodeManagerProtocol {
    var startHandler: (() -> Void)?
    var addLogHandler: ((String) -> Void)?
    var transmitHandler: ((MultipeerTransmitter, ((Result<(), any Error>) -> Void)) -> Void)?

    func start() {
        guard let startHandler else {
            fatalError("startHandler must be set")
        }
        startHandler()
    }
    
    func addLog(_ logStr: String) {
        guard let addLogHandler else {
            fatalError("addLogHandler must be set")
        }
        addLogHandler(logStr)
    }
    
    func transmit(_ transmitter: MultipeerTransmitter, result: @escaping (Result<(), any Error>) -> Void) {
        guard let transmitHandler else {
            fatalError("transmitHandler must be set")
        }
        transmitHandler(transmitter, result)
    }
}

final class NullNodeManager: NodeManagerProtocol {
    func start() {
        fatalError("Null Service Should not be used")
    }

    func addLog(_ logStr: String) {
        fatalError("Null Service Should not be used")
    }

    func transmit(_ transmitter: MultipeerTransmitter, result: @escaping (Result<(), any Error>) -> Void) {
        fatalError("Null Service Should not be used")
    }
}
