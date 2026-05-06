//
//  MultiPeerAdvertiser.swift
//  SensorSuite
//
//  Created by Josh Franco on 4/12/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import MultipeerConnectivity

protocol NearbyServiceAdvertising: AnyObject {
    var delegate: MCNearbyServiceAdvertiserDelegate? { get set }
    func startAdvertisingPeer()
    func stopAdvertisingPeer()
}

extension MCNearbyServiceAdvertiser: NearbyServiceAdvertising {}

protocol MultiPeerAdvertiserProtocol: AnyObject {
    func start()
    func stop()
    var didNotStartAdvertising: (Error) -> Void { get set }
    var invitationReceived: (MCPeerID) -> (Bool, MCSession?) { get set }
}

final class MultiPeerAdvertiser: NSObject, MultiPeerAdvertiserProtocol {
    private let advertiser: NearbyServiceAdvertising
    private let peer: MCPeerID
    private let service: MultiPeerServices
    
    private(set) var isAdvertising = false
    
    var invitationReceived: (MCPeerID) -> (Bool, MCSession?) = { _ in return (false, nil) }
    var didNotStartAdvertising: (Error) -> Void = { _ in }

    private let container: Container
    private let nodeManager: NodeManagerProtocol

    init(for peer: MCPeerID, advertiser: NearbyServiceAdvertising, service: MultiPeerServices = .edge, container: Container = .shared) {
        self.peer = peer
        self.container = container
        self.nodeManager = container.nodeManager.resolve()
        self.advertiser = advertiser
        self.service = service
        super.init()
        self.advertiser.delegate = self
    }

    // MARK: - Init
    init(for peer: MCPeerID, and service: MultiPeerServices, container: Container = .shared) {
        self.container = container
        self.nodeManager = container.nodeManager.resolve()
        let realAdvertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: service.rawValue)
        self.peer = peer
        self.service = service
        self.advertiser = realAdvertiser
        super.init()
        self.advertiser.delegate = self
    }
    
    func start() {
        guard !isAdvertising else { return }
        
        nodeManager.addLog("🕸📲 Start Advertising on \(service.rawValue)")
        isAdvertising.toggle()
        advertiser.startAdvertisingPeer()
    }
    
    func stop() {
        guard isAdvertising else { return }
        
        nodeManager.addLog("🕸📲 Stop Advertising on \(service.rawValue)")
        isAdvertising.toggle()
        
        advertiser.delegate = nil
        advertiser.stopAdvertisingPeer()
    }
}

extension MultiPeerAdvertiser: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        nodeManager.addLog("🕸📲 didReceiveInvitationFromPeer peerID: \(peerID.displayName) on \(service.rawValue)")

        let (invitationAccepted, session) = invitationReceived(peer)
        invitationHandler(invitationAccepted, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        nodeManager.addLog("🕸📲 didNotStartAdvertisingPeer error: \(error.localizedDescription) on \(service.rawValue)")
        logger.error(error.localizedDescription)
        isAdvertising = false
        didNotStartAdvertising(error)
    }
}
