//
//  MultiPeerBrowser.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 12/29/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import MultipeerConnectivity

class MultiPeerBrowser: NSObject {
    private let browser: MCNearbyServiceBrowser
    private let peer: MCPeerID
    private let service: MultiPeerServices
    private let inviteTimeout: TimeInterval = 12
    
    private(set) var isBrowsing = false
    
    var foundPeer: (MCPeerID, [String: String]?) -> Void = { _, _ in }
    var lostPeer: (MCPeerID) -> Void = { _ in }
    var didNotStartBrowsing: (Error) -> Void = { _ in }
    
    // MARK: - Init
    init(for peer: MCPeerID, and service: MultiPeerServices) {
        self.peer = peer
        self.browser = MCNearbyServiceBrowser(peer: peer, serviceType: service.rawValue)
        self.service = service
        
        super.init()
        self.browser.delegate = self
    }
    
    // MARK: - Util
    func start() {
        guard !isBrowsing else { return }
        
        NodeManager.shared.addLog("🕸📲 Start Browsing for \(service)")
        isBrowsing.toggle()
        browser.startBrowsingForPeers()
    }
    
    func stop() {
        guard isBrowsing else { return }
        
        NodeManager.shared.addLog("🕸📲 Stop Browsing for \(service)")
        isBrowsing.toggle()
        browser.stopBrowsingForPeers()
    }
    
    func invitePeer(_ peer: MCPeerID, to session: MCSession) {
        browser.invitePeer(peer, to: session, withContext: nil, timeout: inviteTimeout)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultiPeerBrowser: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard peerID.displayName != peer.displayName else { return }
        NodeManager.shared.addLog("🕸📲 foundPeer peerID: \(peerID.displayName) on service \(service)")
        foundPeer(peerID, info)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NodeManager.shared.addLog("🕸📲 lostPeer peerID: \(peerID.displayName) on service \(service)")
        lostPeer(peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NodeManager.shared.addLog("🕸📲 didNotStartBrowsingForPeers error: \(error.localizedDescription) on service \(service)")
        isBrowsing = false
        didNotStartBrowsing(error)
    }
}
