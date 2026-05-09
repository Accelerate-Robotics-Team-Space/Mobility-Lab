//
//  ProxyAdvertiserNode.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 12/29/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import MultipeerConnectivity

class ProxyAdvertiserNode: NSObject {
    let session: MCSession
    
    var maxPeersCount = 3
    weak var delegate: NodeDelegate?
    
    private let proxyAdvertiser: MultiPeerAdvertiser
    
    init(peerId: MCPeerID) {
        self.session = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .none)
        self.proxyAdvertiser = MultiPeerAdvertiser(for: peerId, and: .proxy)
        
        super.init()
        session.delegate = self
        startObservation()
    }
    
    deinit {
        NodeManager.shared.addLog("DENIT - ProxyNode")
    }
    
    // MARK: - Util
    func start() {
        proxyAdvertiser.start()
    }
    
    func stop() {
        session.disconnect()
        proxyAdvertiser.stop()
    }
}

// MARK: - Private Methods
private extension ProxyAdvertiserNode {
    func startObservation() {
        proxyAdvertiser.invitationReceived = { [weak self] _ in
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
extension ProxyAdvertiserNode: MCSessionDelegate {
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
        NodeManager.shared.addLog("🕸📲 Hit didReceiveCertificate certificate: \(certificate ?? [])")
        
        certificateHandler(true)
    }
}
