//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import MultipeerConnectivity
@testable import MobilityLab_BMM
import XCTest

final class ProxyNodeTests: XCTestCase {
    private var peerID: MCPeerID!
    private var container: Container!
    private var nodeManager: MockNodeManager!
    private var securityService: MockSecurityService!
    private var keychain: MockKeychain!
    private var testSubject: ProxyNode!

    override func setUp() {
        super.setUp()
        container = .init()
        container.resetAll()

        peerID = MCPeerID(displayName: "proxyTests")
        nodeManager = MockNodeManager()
        securityService = MockSecurityService()
        keychain = MockKeychain()
        nodeManager.addLogHandler = { _ in }

        container.keychain.register { self.keychain }
        container.nodeManager.register { self.nodeManager }
        container.securityService.register { self.securityService }

        testSubject = ProxyNode(peerId: peerID, container: container, interval: 1)
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        keychain = nil
        securityService = nil
        nodeManager = nil
        peerID = nil
        container = nil
    }

    func testStart() {
        testSubject.start()
    }
}
