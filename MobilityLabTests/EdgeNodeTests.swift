//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import MultipeerConnectivity
@testable import MobilityLab_BMM
import XCTest

final class EdgeNodeTests: XCTestCase {
    var peer: MCPeerID!
    private var container: Container!
    private var advertiser: MockMultiPeerAdvertiser!
    private var nodeManager: MockNodeManager!
    private var securityService: MockSecurityService!
    private var keychain: MockKeychain!
    private var testSubject: EdgeNode!

    override func setUp() {
        super.setUp()
        peer = MCPeerID(displayName: "123")
        container = .init()
        container.resetAll()

        advertiser = MockMultiPeerAdvertiser()
        nodeManager = MockNodeManager()
        securityService = MockSecurityService()
        keychain = MockKeychain()
        nodeManager.addLogHandler = { _ in }

        container.nodeManager.register { self.nodeManager }
        container.securityService.register { self.securityService }
        container.keychain.register { self.keychain }

        testSubject = EdgeNode(peerId: peer, container: container, advertiser: advertiser)
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        keychain = nil
        securityService = nil
        nodeManager = nil
        advertiser = nil
        container = nil
        peer = nil
    }

    func testStart() {
        let exp = expectation(description: #function)
        var didStart = false
        advertiser.startHandler = {
            didStart = true
            exp.fulfill()
        }

        testSubject.start(oldEdgePeer: nil)

        wait(for: [exp], timeout: 1)
        XCTAssertTrue(didStart)
    }

    func testStop() {
        let exp = expectation(description: #function)
        var didStop = false
        advertiser.stopHandler = {
            didStop = true
            exp.fulfill()
        }

        testSubject.stop()

        wait(for: [exp], timeout: 1)
        XCTAssertTrue(didStop)

    }
}
