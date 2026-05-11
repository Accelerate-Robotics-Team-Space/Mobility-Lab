//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import MultipeerConnectivity
@testable import MobilityLab_BMM

final class MockMultiPeerAdvertiser: MultiPeerAdvertiserProtocol {
    var startHandler: (() -> Void)?
    var stopHandler: (() -> Void)?

    var didNotStartAdvertising: (any Error) -> Void = { _ in }

    var invitationReceived: (MCPeerID) -> (Bool, MCSession?) = { _ in return (false, nil) }

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

    func sendInvitation(_ from: MCPeerID) -> (Bool, MCSession?) {
        invitationReceived(from)
    }
}

final class NullMultiPeerAdvertiser: MultiPeerAdvertiserProtocol {
    func start() {
        fatalError("Null Service Should not be used")
    }

    func stop() {
        fatalError("Null Service Should not be used")
    }

    var didNotStartAdvertising: (any Error) -> Void {
        get { fatalError("Null Service Should not be used") }
        set { _ = newValue; fatalError("Null Service Should not be used") }
    }

    var invitationReceived: (MCPeerID) -> (Bool, MCSession?) {
        get { fatalError("Null Service Should not be used") }
        set { _ = newValue; fatalError("Null Service Should not be used") }
    }
}
