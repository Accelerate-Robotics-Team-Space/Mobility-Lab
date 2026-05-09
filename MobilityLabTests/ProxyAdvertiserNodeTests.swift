//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import MultipeerConnectivity
@testable import MobilityLab_BMM
import XCTest

final class ProxyAdvertiserNodeTests: XCTestCase {
    private var peerID: MCPeerID!
    private var container: Container!
    private var proxyAdvertiser: MockMultiPeerAdvertiser!
    private var session: MockPeerSession!
    private var nodeManager: MockNodeManager!

    private var testSubject: ProxyAdvertiserNode!

    override func setUp() {
        super.setUp()
        container = .init()
        container.resetAll()

        peerID = MCPeerID(displayName: "proxyTests")
        nodeManager = MockNodeManager()
        proxyAdvertiser = MockMultiPeerAdvertiser()
        session = MockPeerSession()
        nodeManager.addLogHandler = { _ in }
        container.nodeManager.register { self.nodeManager }

        testSubject = ProxyAdvertiserNode(
            peerId: peerID,
            container: container,
            proxyAdvertiser: proxyAdvertiser,
            session: session
        )
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        proxyAdvertiser = nil
        nodeManager = nil
        peerID = nil
        session = nil
        container = nil
    }

    func testStart() {
        let exp = expectation(description: #function)
        var startWasCalled = false
        proxyAdvertiser.startHandler = {
            startWasCalled = true
            exp.fulfill()
        }
        testSubject.start()

        wait(for: [exp], timeout: 1)
        XCTAssertTrue(startWasCalled)
    }

    func testInvitationReceived_belowThreshold() {
        session.connectedPeers = [.init(displayName: "1"), .init(displayName: "2")]
        let (success, _) = proxyAdvertiser.sendInvitation(.init(displayName: "3"))
        XCTAssertTrue(success)
    }

    func testInvitationReceived_aboveThreshold() {
        session.connectedPeers = [
            .init(displayName: "1"),
            .init(displayName: "2"),
            .init(displayName: "3"),
            .init(displayName: "4"),
        ]
        let (success, _) = proxyAdvertiser.sendInvitation(.init(displayName: "5"))
        XCTAssertFalse(success)
    }
}
