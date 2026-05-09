//
//  NodeManager.swift
//  MobilityLab
//
//  Created by Josh Franco on 4/12/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import MultipeerConnectivity

protocol NodeManagerProtocol: AnyObject {
    func start()
    func addLog(_ logStr: String)
    func transmit(_ transmitter: MultipeerTransmitter, result: @escaping (Result<(), Error>) -> Void)
}

extension Container {
    var nodeManager: Factory<NodeManagerProtocol> {
        self { NodeManager() }.cached
    }
}

final class NodeManager: NodeManagerProtocol {
    enum NodeError: Error {
        case noEdgeSession
        case noProxySession
        case noProxyEdgePeer
    }

    enum NodeType: String {
        case edge = "Edge"
        case proxyEdge = "Proxy Edge"
        case proxy = "Proxy"
        case none = "N/A"
    }

    private let peerCountOptions = [1, 2, 3, 5, 7]
    private let nodeQueue = DispatchQueue(label: "ALT_Mesh_Network", qos: .userInitiated)
    private let logInterval: TimeInterval
    private(set) var logs: [String] = []

    private var connectedEdgePeers: [String] = []
    private var connectedProxyPeers: [String] = []
    private var connectedProxyAdvertPeers: [String] = []
    private(set) var nodeType: NodeType = .none
    private var dataToBeTransmitted: [Data] = []
    private var isTransmitting = false
    private var maxPeerCountIndex = 2 {
        didSet {
            let peerCount = peerCountOptions[maxPeerCountIndex]
            
            edge?.maxPeersCount = peerCount
            proxyAdvertiser?.maxPeersCount = peerCount
        }
    }

    private let peerId: MCPeerID
    private(set) var edge: EdgeNode?
    private(set) var proxy: ProxyNode?
    private var proxyAdvertiser: ProxyAdvertiserNode?

    // MARK: Services
    let container: Container
    private let networkMonitor: NetworkMonitorProtocol
    private let notificationCenter: NotificationCenterServiceProtocol
    private let mqttService: MQTTServiceProtocol
    private let multiPeerAdvertiser: (any MultiPeerAdvertiserProtocol)?

    // MARK: - Computed Variables
    private var isNetConnected: Bool {
        networkMonitor.isConnected
    }
    
    private var allPeers: [MCPeerID] {
        let edgePeers = self.edge?.session.connectedPeers ?? []
        let proxyPeers = self.proxy?.session.connectedPeers ?? []
        let proxyAdvPeers = self.proxyAdvertiser?.session.connectedPeers ?? []
        
        return edgePeers + proxyPeers + proxyAdvPeers
    }
    
    // MARK: - Init
    convenience init(
        container: Container = .shared,
        logInterval: TimeInterval = 75,
        advertiser: (any MultiPeerAdvertiserProtocol)? = nil
    ) {
        let userDefaults = container.userDefaults.resolve()
        let peerIDKey = userDefaults.incrementPeerIDKey()
        self.init(
            peerID: MCPeerID(displayName: "\(UIDevice.current.name)_\(peerIDKey)"),
            container: container,
            logInterval: logInterval,
            advertiser: advertiser
        )
    }

    init(
        peerID: MCPeerID,
        container: Container = .shared,
        logInterval: TimeInterval = 75,
        advertiser: (any MultiPeerAdvertiserProtocol)? = nil
    ) {
        self.container = container
        self.peerId = peerID
        self.logInterval = logInterval
        self.networkMonitor = container.networkMonitor.resolve()
        self.notificationCenter = container.notificationCenter.resolve()
        self.mqttService = container.mqttService.resolve()
        self.multiPeerAdvertiser = advertiser
        addLog("🕸📲 Making Session with peer: \(peerId.displayName)")
        configureNotifications()
    }

    private func configureNotifications() {
        notificationCenter.addObserver(self, selector: #selector(connectionHandler), name: NetworkMonitor.connectionNote, object: nil)
        notificationCenter.addObserver(self, selector: #selector(disconnectionHandler), name: NetworkMonitor.disconnectionNote, object: nil)
    }

    // MARK: - Util
    func start() {
        logActivity()
    }
    
    func addLog(_ logStr: String) {
        nodeQueue.asyncAfter(deadline: .now() + logInterval) {
            self.logs.append(logStr)
        }
    }
    
    func transmit(_ transmitter: MultipeerTransmitter, result: @escaping (Result<(), Error>) -> Void) {
        do {
            let transmitData = transmitter.toData()
            
            if isNetConnected {
                guard let edgeSession = edge?.session else { throw NodeError.noEdgeSession }
                try edgeSession.send(transmitData, toPeers: allPeers, with: .reliable)
            } else {
                guard let proxySession = proxy?.session else { throw NodeError.noProxySession }
                
                if let edgePeer = proxy?.edgePeer {
                    try proxySession.send(transmitData, toPeers: [edgePeer], with: .reliable)
                } else {
                    guard let proxyPeer = proxy?.proxyEdgePeer else { throw NodeError.noProxyEdgePeer }
                    try proxySession.send(transmitData, toPeers: [proxyPeer], with: .reliable)
                }
            }
            
            result(.success)
        } catch {
            addLog("🕸📲 \(error.localizedDescription)")
            logger.error(error.localizedDescription)
            result(.failure(error))
        }
    }
}

// MARK: - Private
private extension NodeManager {
    func trasmitData() {
        nodeQueue.async { [weak self] in
            guard
                !(self?.isTransmitting == true), let data = self?.dataToBeTransmitted.popLast(),
                let trasmitData = try? JSONDecoder().decode(MultipeerTransmitter.self, from: data) else { return }

            if self?.mqttService.status != .connected {
                self?.isTransmitting.toggle()
                self?.mqttService.executeOnConnection { [weak self] in
                    self?.isTransmitting.toggle()
                    self?.trasmitData()
                }
            } else {
                self?.isTransmitting.toggle()
                self?.mqttService.publish(trasmitData.data, to: trasmitData.topic, isRetained: false, qos: .atLeastOnce) { result in
                    self?.isTransmitting.toggle()
                    switch result {
                    case .success:
                        self?.trasmitData()
                    case .failure(let error):
                        self?.addLog(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    // MARK: - Logging
    func logActivity() {
        nodeQueue.asyncAfter(deadline: .now() + logInterval) { [weak self] in
            if !(self?.logs.isEmpty == true) {
                var logStr = "Mesh Network Activity: \n"
                for log in (self?.logs ?? []) {
                    logStr += "\(log) \n"
                }
                
                logger.info(logStr)
                self?.logs.removeAll()
            }
            
            self?.logActivity()
        }
    }
    
    // MARK: - @Objc
    @objc
    func connectionHandler() {
        guard edge == nil else { return }
        
        let proxyEdge = proxy?.edgePeer
        proxy?.stop()
        proxy = nil
        
        proxyAdvertiser?.stop()
        proxyAdvertiser = nil
        
        edge = EdgeNode(peerId: peerId, container: container, advertiser: multiPeerAdvertiser)
        edge?.delegate = self
        edge?.start(oldEdgePeer: proxyEdge)
        nodeType = .edge
    }
    
    @objc
    func disconnectionHandler() {
        guard proxy == nil else { return }
        
        edge?.stop()
        edge = nil
        
        proxy = ProxyNode(peerId: peerId, container: container)
        proxy?.delegate = self
        proxy?.start()
        nodeType = .proxy
    }
}

// MARK: - NodeDelegate
extension NodeManager: NodeDelegate {
    func sessionDidChange(_ session: MCSession, to state: MCSessionState) {
        switch state {
        case .connected, .notConnected:
            DispatchQueue.main.async { [weak self] in
                self?.connectedEdgePeers = self?.edge?.session.connectedPeers.map({ $0.displayName }) ?? []
                self?.connectedProxyPeers = self?.proxy?.session.connectedPeers.map({ $0.displayName }) ?? []
                self?.connectedProxyAdvertPeers = self?.proxyAdvertiser?.session.connectedPeers.map({ $0.displayName }) ?? []
            }
        default: break
        }
    }
    
    func didReceive(_ data: Data, fromPeer peerID: MCPeerID) {
        // if we are not connected to the internet we must pass along the msg to a peer that is connected to the net
        if isNetConnected {
            dataToBeTransmitted.insert(data, at: 0)
            trasmitData()
        } else {
            guard let proxySession = proxy?.session else { return }
            
            do {
                var peersToReceive: [MCPeerID] = []
                if let edgePeer = proxy?.edgePeer {
                    peersToReceive = [edgePeer]
                } else if let proxyPeer = proxy?.proxyEdgePeer {
                    peersToReceive = [proxyPeer]
                }
                
                try proxySession.send(data, toPeers: peersToReceive, with: .reliable)
            } catch {
                self.addLog(error.localizedDescription)
            }
        }
    }
}

extension NodeManager: ProxyNodeDelegate {
    func edgeConnectionUpdated(with edgePeer: MCPeerID?) {
        guard !isNetConnected else { return }
        
        if edgePeer == nil {
            proxyAdvertiser?.stop()
            proxyAdvertiser = nil
            
            DispatchQueue.main.async { [weak self] in
                self?.nodeType = .proxy
            }
        } else {
            proxyAdvertiser = ProxyAdvertiserNode(peerId: peerId)
            proxyAdvertiser?.delegate = self
            proxyAdvertiser?.start()
            
            DispatchQueue.main.async { [weak self] in
                self?.nodeType = .proxyEdge
            }
        }
    }
}
