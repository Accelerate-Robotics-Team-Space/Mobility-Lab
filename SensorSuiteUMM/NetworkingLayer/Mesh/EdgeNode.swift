//
//  EdgeNode.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 12/29/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import MultipeerConnectivity

protocol NodeDelegate: AnyObject {
    func sessionDidChange(_ session: MCSession, to state: MCSessionState)
    func didReceive(_ data: Data, fromPeer peerID: MCPeerID)
}

class EdgeNode: NSObject {
    let session: MCSession
    
    var maxPeersCount = 3
    weak var delegate: NodeDelegate?
    
    @Injected(\.securityService)
    private var securityService
    private let advertiser: MultiPeerAdvertiser
    
    // MARK: - Init
    init(peerId: MCPeerID) {
        let securityIdentity: [Any]?
        if let identity = Keychain.shared.deviceCertIdentity {
            securityIdentity = [identity]
        } else {
            securityIdentity = nil
        }
        
        self.session = MCSession(peer: peerId,
                                 securityIdentity: securityIdentity,
                                 encryptionPreference: .required)
        self.advertiser = MultiPeerAdvertiser(for: peerId, and: .edge)
        
        super.init()
        
        session.delegate = self
        startObservation()
    }
    
    deinit {
        NodeManager.shared.addLog("DENIT - EdgeNode")
    }
    
    // MARK: - Util
    func start(oldEdgePeer: MCPeerID?) {
        // "need to tell all connected peers its a edge node"
        if let oldEdgePeer = oldEdgePeer {
            session.cancelConnectPeer(oldEdgePeer)
        }
        
        advertiser.start()
    }
    
    func stop() {
        session.disconnect()
        advertiser.stop()
    }
}

// MARK: - Private
private extension EdgeNode {
    func startObservation() {
        advertiser.invitationReceived = { [weak self] _ in
            guard let self = self else { return (false, nil) }
            
            if self.session.connectedPeers.count < self.maxPeersCount {
                return (true, self.session)
            } else {
                return (false, self.session)
            }
        }
    }
}

// MARK: - MCSessionDelegate
extension EdgeNode: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        delegate?.sessionDidChange(session, to: state)
        
        switch state {
        case .connected:
            NodeManager.shared.addLog("🕸📲 Connected: \(peerID.displayName)")
        case .connecting:
            NodeManager.shared.addLog("🕸📲 Connecting: \(peerID.displayName)")
        case .notConnected:
            NodeManager.shared.addLog("🕸📲 Not Connected: \(peerID.displayName)")
        @unknown default: break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NodeManager.shared.addLog("🕸📲 Hit didReceive data: \(String(decoding: data, as: UTF8.self))")
        delegate?.didReceive(data, fromPeer: peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NodeManager.shared.addLog("🕸📲 Hit didReceive stream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NodeManager.shared.addLog("🕸📲 Hit didStartReceivingResourceWithName resourceName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NodeManager.shared.addLog("🕸📲 Hit didFinishReceivingResourceWithName resourceName")
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?,
                 fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        securityService.evaluateMeshCerts(certificate) { result in
            switch result {
            case .success:
                certificateHandler(true)
            case .failure(let error):
                logger.error("didReceiveCertificate failed! Error: \(error.localizedDescription)")
                certificateHandler(false)
            }
        }
    }
}
