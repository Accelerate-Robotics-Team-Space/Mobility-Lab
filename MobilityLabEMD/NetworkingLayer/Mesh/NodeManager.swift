//
//  NodeManager.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 12/29/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import MultipeerConnectivity

enum NodeType: String {
    case edge = "Edge"
    case proxyEdge = "Proxy Edge"
    case proxy = "Proxy"
    case none = "N/A"
}

class NodeManager {
    static let shared = NodeManager()
    
    private let peerCountOptions = [1, 2, 3, 5, 7]
    private let nodeQueue = DispatchQueue(label: "ALT_Mesh_Network",
                                          qos: .userInitiated)
    private let logInterval: TimeInterval = 75
    private var logs: [String] = []
    
    private var connectedEdgePeers: [String] = []
    private var connectedProxyPeers: [String] = []
    private var connectedProxyAdvertPeers: [String] = []
    private var nodeType: NodeType = .none
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
    private var edge: EdgeNode?
    private var proxy: ProxyNode?
    private var proxyAdvertiser: ProxyAdvertiserNode?
    
    // MARK: - Computed Variables
    private var isNetConnected: Bool {
        NetworkMonitor.shared.isNetworkAvailable
    }
    
    private var allPeers: [MCPeerID] {
        let edgePeers = self.edge?.session.connectedPeers ?? []
        let proxyPeers = self.proxy?.session.connectedPeers ?? []
        let proxyAdvPeers = self.proxyAdvertiser?.session.connectedPeers ?? []
        
        return edgePeers + proxyPeers + proxyAdvPeers
    }
    
    // MARK: - Init
    init() {
        UserDefaults.standard.peerIdKey += 1
        let peerIdKey = UserDefaults.standard.peerIdKey
        peerId = MCPeerID(displayName: "\(UIDevice.current.name)_\(peerIdKey)")
        logs.append("🕸📲 Making Session with peer: \(UIDevice.current.name)_\(peerIdKey)")
        
        NotificationCenter.default.addObserver(self, selector: #selector(connectionHandler),
                                               name: NetworkMonitor.connectionNote, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnectionHandler),
                                               name: NetworkMonitor.disconnectionNote, object: nil)
    }
    
    // MARK: - Util
    func start() {
        logActivity()
    }
    
    func addLog(_ logStr: String) {
        logs.append(logStr)
    }
    
    func trasnmit(_ transmitter: MultipeerTransmitter, result: @escaping (Result<(), Error>) -> Void) {
        do {
            let trasnmitData = transmitter.toData()
            
            if isNetConnected {
                guard let edgeSession = edge?.session else { throw NodeErr.noEdgeSession }
                try edgeSession.send(trasnmitData, toPeers: allPeers, with: .reliable)
            } else {
                guard let proxySession = proxy?.session else { throw NodeErr.noProxySession }
                
                if let edgePeer = proxy?.edgePeer {
                    try proxySession.send(trasnmitData, toPeers: [edgePeer], with: .reliable)
                } else {
                    guard let proxyPeer = proxy?.proxyEdgePeer else { throw NodeErr.noProxyEdgePeer }
                    try proxySession.send(trasnmitData, toPeers: [proxyPeer], with: .reliable)
                }
            }
            
            result(.success)
        } catch {
            logs.append("🕸📲 \(error.localizedDescription)")
            result(.failure(error))
        }
    }
}

// MARK: - Private
private extension NodeManager {
    enum NodeErr: Error {
        case noEdgeSession
        case noProxySession
        case noProxyEdgePeer
    }
    
    func trasmitData() {
            guard
                !self.isTransmitting, let data = self.dataToBeTransmitted.popLast(),
                (try? JSONDecoder().decode(MultipeerTransmitter.self, from: data)) != nil else { return }

            if MQTTService.shared.status != .connected {
                self.isTransmitting.toggle()
                MQTTService.shared.connect()
                self.isTransmitting.toggle()
            } else {
                self.isTransmitting.toggle()
//                MQTTService.shared.publish(trasmitData.data, to: trasmitData.topic,
//                                          isRetained: false, qos: .atLeastOnce) { result in
//                    self.isTransmitting.toggle()
//                    switch result {
//                    case .success:
//                        await self.trasmitData()
//                    case .failure(let error):
//                        self.logs.append(error.localizedDescription)
//                    }
//                }
            }
//        }
    }
    
    // MARK: - Logging
    func logActivity() {
        nodeQueue.asyncAfter(deadline: .now() + logInterval) {
            if !self.logs.isEmpty {
                var logStr = "Mesh Network Activity: \n"
                for log in self.logs {
                    logStr += "\(log) \n"
                }
                
                logger.info(logStr)
                self.logs.removeAll()
            }
            
            self.logActivity()
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
        
        edge = EdgeNode(peerId: peerId)
        edge?.delegate = self
        edge?.start(oldEdgePeer: proxyEdge)
        nodeType = .edge
    }
    
    @objc
    func disconnectionHandler() {
        guard proxy == nil else { return }
        
        edge?.stop()
        edge = nil
        
        proxy = ProxyNode(peerId: peerId)
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
                logs.append(error.localizedDescription)
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
            
            DispatchQueue.main.async {
                self.nodeType = .proxy
            }
        } else {
            proxyAdvertiser = ProxyAdvertiserNode(peerId: peerId)
            proxyAdvertiser?.delegate = self
            proxyAdvertiser?.start()
            
            DispatchQueue.main.async {
                self.nodeType = .proxyEdge
            }
        }
    }
}
