//
//  MultiPeerAdvertiser.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 12/29/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import MultipeerConnectivity

class MultiPeerAdvertiser: NSObject {
    private let advertiser: MCNearbyServiceAdvertiser
    private let peer: MCPeerID
    private let service: MultiPeerServices
    
    private(set) var isAdvertising = false
    
    var invitationReceived: (MCPeerID) -> (Bool, MCSession?) = { _ in return (false, nil) }
    var didNotStartAdvertising: (Error) -> Void = { _ in }
    
    // MARK: - Init
    init(for peer: MCPeerID, and service: MultiPeerServices) {
        self.peer = peer
        self.advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: service.rawValue)
        self.service = service
        
        super.init()
        self.advertiser.delegate = self
    }
    
    func start() {
        guard !isAdvertising else { return }
        
        NodeManager.shared.addLog("🕸📲 Start Advertising on \(service)")
        isAdvertising.toggle()
        advertiser.startAdvertisingPeer()
    }
    
    func stop() {
        guard isAdvertising else { return }
        
        NodeManager.shared.addLog("🕸📲 Stop Advertising on \(service)")
        isAdvertising.toggle()
        
        advertiser.delegate = nil
        advertiser.stopAdvertisingPeer()
    }
}

extension MultiPeerAdvertiser: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NodeManager.shared.addLog("🕸📲 didReceiveInvitationFromPeer peerID: \(peerID.displayName) on \(service)")
        
        let (invitationAccepted, session) = invitationReceived(peer)
        invitationHandler(invitationAccepted, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NodeManager.shared.addLog("🕸📲 didNotStartAdvertisingPeer error: \(error.localizedDescription) on \(service)")
        isAdvertising = false
        didNotStartAdvertising(error)
    }
}
