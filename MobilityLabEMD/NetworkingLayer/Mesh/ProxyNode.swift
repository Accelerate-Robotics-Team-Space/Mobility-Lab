//
//  ProxyNode.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 12/29/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import MultipeerConnectivity

protocol ProxyNodeDelegate: AnyObject {
    func sessionDidChange(_ session: MCSession, to state: MCSessionState)
    func didReceive(_ data: Data, fromPeer peerID: MCPeerID)
    func edgeConnectionUpdated(with edgePeer: MCPeerID?)
}

class ProxyNode: NSObject {
    let session: MCSession
    
    weak var delegate: ProxyNodeDelegate?
    
    @Injected(\.securityService) 
    private var securityService
    private let edgeBrowser: MultiPeerBrowser
    private let proxyBrowser: MultiPeerBrowser
    
    private var executeProxyBrowse = false
    private var currentState: MCSessionState = .notConnected
    private var backupPeers: [BackupPeer] = []
    private var attemptedEdgePeers: Set<MCPeerID> = []
    private var attemptedProxyPeers: Set<MCPeerID> = []
    
    private(set) var proxyEdgePeer: MCPeerID?
    private(set) var edgePeer: MCPeerID? {
        didSet {
            delegate?.edgeConnectionUpdated(with: edgePeer)
        }
    }

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
        self.edgeBrowser = MultiPeerBrowser(for: peerId, and: .edge)
        self.proxyBrowser = MultiPeerBrowser(for: peerId, and: .proxy)
        
        super.init()
        
        session.delegate = self
        startObservation()
    }
    
    deinit {
        NodeManager.shared.addLog("DENIT - ProxyNode")
    }
    
    // MARK: - Util
    func start() {
        edgeBrowser.start()
        startProxyBrowserTimer()
    }
    
    func stop() {
        edgeBrowser.stop()
        proxyBrowser.stop()
    }
    
    func restart() {
        edgeBrowser.stop()
        proxyBrowser.stop()
        
        edgeBrowser.start()
        startProxyBrowserTimer()
    }
}

// MARK: - Private
private extension ProxyNode {
    struct BackupPeer: Hashable, Equatable {
        let peer: MCPeerID
        let isEdgePeer: Bool
    }
    
    func startObservation() {
        edgeBrowser.foundPeer = { [weak self] peer, _ in
            guard let self = self else { return }

            switch self.currentState {
            case .notConnected:
                self.attemptedEdgePeers.insert(peer)
                self.currentState = .connecting
                self.edgeBrowser.invitePeer(peer, to: self.session)
            case .connecting:
                self.addBackupPeer(BackupPeer(peer: peer, isEdgePeer: true))
            case .connected:
                guard self.edgePeer == nil else { return }
                
                self.attemptedEdgePeers.insert(peer)
                self.currentState = .connecting
                self.edgeBrowser.invitePeer(peer, to: self.session)
            @unknown default: break
            }
        }

        proxyBrowser.foundPeer = { [weak self] peer, _ in
            guard let self = self else { return }
            
            switch self.currentState {
            case .notConnected:
                self.attemptedProxyPeers.insert(peer)
                self.currentState = .connecting
                self.proxyBrowser.invitePeer(peer, to: self.session)
            case .connecting:
                self.addBackupPeer(BackupPeer(peer: peer, isEdgePeer: false))
            case .connected: break
            @unknown default: break
            }
        }
    }
    
    // MARK: - Mesh Methods
    func addBackupPeer(_ backupPeer: BackupPeer) {
        if backupPeer.isEdgePeer {
            // If the peer is a edge peer then add to the end of the arr
            backupPeers.append(backupPeer)
        } else {
            // If the peer is a edge peer then add to the start of the arr
            backupPeers.insert(backupPeer, at: 0)
        }
    }
    
    func connectToBackupPeer() {
        guard let backupPeer = backupPeers.popLast() else { return }
        
        if backupPeer.isEdgePeer {
            edgeBrowser.invitePeer(backupPeer.peer, to: session)
        } else {
            proxyBrowser.invitePeer(backupPeer.peer, to: session)
        }
    }
    
    /// Connect to a peer, if its a edge then stop all browsing, if its a proxy edge then keep browsing for a edge
    /// - Parameter peer: The peer to connect too
    func connect(to peer: MCPeerID) {
        // Stop the Proxy Browser & timer
        stopProxyBrowserTimer()
        proxyBrowser.stop()
        
        if attemptedEdgePeers.contains(peer) {
            // Cannot be connected to two edge peers at once
            if let existingEdgePeer = edgePeer {
                session.cancelConnectPeer(existingEdgePeer)
            }
            
            if let proxyPeer = proxyEdgePeer {
                proxyEdgePeer = nil
                session.cancelConnectPeer(proxyPeer)
            }
            
            edgeBrowser.stop()
            edgePeer = peer
        } else if attemptedProxyPeers.contains(peer) {
            proxyEdgePeer = peer
        }
        
        backupPeers.removeAll()
        attemptedEdgePeers.removeAll()
        attemptedProxyPeers.removeAll()
    }
    
    /// If the peer is a edge peer nil out the referance and start browsing for a new edge, if its the proxyEdge then
    /// nil out the proxyEdge and start browsing IF there is no edge peer (there shold not be). If its none of those then attempt to connect
    /// to a backup peer
    /// - Parameter peer: The peer to disconnect from
    func disconnect(from peer: MCPeerID) {
        switch peer {
        case edgePeer:
            edgePeer = nil
            restart()
            
            if proxyEdgePeer == nil {
                session.disconnect()
            }
        case proxyEdgePeer:
            proxyEdgePeer = nil
            
            if edgePeer == nil {
                session.disconnect()
                restart()
            }
        default:
            connectToBackupPeer()
        }
    }
    
    // MARK: - Timer
    func startProxyBrowserTimer(with timeInterval: TimeInterval = 10) {
        executeProxyBrowse = true
        
        DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) { [weak self] in
            guard
                let self = self,
                self.executeProxyBrowse,
                self.proxyEdgePeer == nil else { return }
            
            self.proxyBrowser.start()
        }
    }
    
    func stopProxyBrowserTimer() {
        executeProxyBrowse = false
    }
}

// MARK: - MCSessionDelegate
extension ProxyNode: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        delegate?.sessionDidChange(session, to: state)
        currentState = state
        
        switch state {
        case .notConnected:
            NodeManager.shared.addLog("🕸📲 Not Connected: \(peerID.displayName)")
            disconnect(from: peerID)
        case .connecting:
            NodeManager.shared.addLog("🕸📲 Connecting: \(peerID.displayName)")
        case .connected:
            NodeManager.shared.addLog("🕸📲 Connected: \(peerID.displayName)")
            connect(to: peerID)
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
