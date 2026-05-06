//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import MultipeerConnectivity
@testable import SensorSuite_BMM

final class MockPeerSession: PeerSessionProtocol {
    var disconnectHandler: (() -> Void)?

    func disconnect() {
        guard let disconnectHandler else {
            fatalError("disconnectHandler must be set")
        }
        disconnectHandler()
    }

    weak var delegate: MCSessionDelegate?

    var connectedPeers: [MCPeerID] = []

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        delegate?.session(session, peer: peerID, didChange: state)
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        delegate?.session(session, didReceive: data, fromPeer: peerID)
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        delegate?.session(session, didReceive: stream, withName: streamName, fromPeer: peerID)
    }

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        delegate?.session(session, didStartReceivingResourceWithName: resourceName, fromPeer: peerID, with: progress)
    }

    func session(
        _ session: MCSession,
        didReceiveCertificate certificate: [Any]?,
        fromPeer peerID: MCPeerID,
        certificateHandler: @escaping (Bool) -> Void
    ) {
        delegate?.session?(session, didReceiveCertificate: certificate, fromPeer: peerID, certificateHandler: certificateHandler)
    }

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {
        delegate?.session(session, didFinishReceivingResourceWithName: resourceName, fromPeer: peerID, at: localURL, withError: error)
    }
}
