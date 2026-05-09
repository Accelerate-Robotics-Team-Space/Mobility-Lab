//
//  ProxyAdvertiserNode.swift
//  MobilityLab
//
//  Created by Josh Franco on 4/12/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import MultipeerConnectivity

class ProxyAdvertiserNode: NSObject {
    let session: PeerSessionProtocol

    var maxPeersCount = 3
    weak var delegate: NodeDelegate?

    private let container: Container
    private let proxyAdvertiser: MultiPeerAdvertiserProtocol
    private let nodeManager: NodeManagerProtocol

    init(
        peerId: MCPeerID,
        container: Container = .shared,
        proxyAdvertiser: MultiPeerAdvertiserProtocol? = nil,
        session: (any PeerSessionProtocol)? = nil
    ) {
        self.container = container
        self.nodeManager = container.nodeManager.resolve()
        self.session = session ?? MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .none)
        self.proxyAdvertiser = proxyAdvertiser ?? MultiPeerAdvertiser(for: peerId, and: .proxy, container: container)

        super.init()
        self.session.delegate = self
        startObservation()
    }
    
    deinit {
        nodeManager.addLog("DENIT - ProxyNode")
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
                return (true, self.session as? MCSession)
            } else {
                return (false, self.session as? MCSession)
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
            nodeManager.addLog("🕸📲 Connected: \(peerID.displayName)")
        case .connecting:
            nodeManager.addLog("🕸📲 Connecting: \(peerID.displayName)")
        case .notConnected:
            nodeManager.addLog("🕸📲 Not Connected: \(peerID.displayName)")
        @unknown default: break
        }
    }
    
    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        nodeManager.addLog("🕸📲 Hit didReceive data: \(String(decoding: data, as: UTF8.self))")
        delegate?.didReceive(data, fromPeer: peerID)
    }
    
    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        nodeManager.addLog("🕸📲 Hit didReceive stream")
    }
    
    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        nodeManager.addLog("🕸📲 Hit didStartReceivingResourceWithName resourceName")
    }
    
    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {
        nodeManager.addLog("🕸📲 Hit didFinishReceivingResourceWithName resourceName")
    }
    
    func session(
        _ session: MCSession,
        didReceiveCertificate certificate: [Any]?,
        fromPeer peerID: MCPeerID,
        certificateHandler: @escaping (Bool) -> Void
    ) {
        nodeManager.addLog("🕸📲 Hit didReceiveCertificate certificate: \(certificate ?? [])")
        
        certificateHandler(true)
    }
}

protocol PeerSessionProtocol: AnyObject {
    func disconnect()
    var delegate: MCSessionDelegate? { get set }
    var connectedPeers: [MCPeerID] { get }
}

extension MCSession: PeerSessionProtocol { }
