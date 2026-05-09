//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import MultipeerConnectivity
@testable import MobilityLab_BMM
import XCTest

final class MultiPeerAdvertiserTests: XCTestCase {
    var peer: MCPeerID!
    var fake: FakeAdvertiser!
    var container: Container!
    var nodeManager: MockNodeAdvertiser!
    var session: MCSession!
    var sut: MultiPeerAdvertiser!

    override func setUp() {
        super.setUp()
        nodeManager = MockNodeAdvertiser()
        container = .init()
        container.resetAll()
        container.nodeManager.register { self.nodeManager }
        peer = makePeer()
        fake = FakeAdvertiser()
        sut = MultiPeerAdvertiser(for: peer, advertiser: fake, container: container)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        session = nil
        nodeManager = nil
        container = nil
        fake = nil
        peer = nil
    }

    func testStartStartsAdvertisingOnceAndLogs() throws {
        // GIVEN - a MultiPeerAdvertiser with a fake advertiser

        // WHEN - start called twice
        sut.start()
        sut.start()

        // THEN - start called once and isAdvertising true, and log captured
        XCTAssertEqual(fake.startCalls, 1)
        XCTAssertTrue(sut.isAdvertising)
        assertLogsContain("Start Advertising on \(MultiPeerServices.edge.rawValue)", in: nodeManager)
    }

    func testStopStopsAdvertisingOnceClearsDelegateAndLogs() throws {
        // GIVEN - started advertiser
        sut.start()

        // WHEN - stop called twice
        sut.stop()
        sut.stop()

        // THEN - stop called once, isAdvertising false, delegate cleared, and log captured
        XCTAssertEqual(fake.stopCalls, 1)
        XCTAssertFalse(sut.isAdvertising)
        XCTAssertNil(fake.delegate)
        assertLogsContain("Stop Advertising on \(MultiPeerServices.edge.rawValue)", in: nodeManager)
    }

    func testDidReceiveInvitationForwardsToClosureAndLogs() throws {
        // GIVEN - closure returning true and a session
        let session = makeSession(peer: peer)

        sut.invitationReceived = { _ in
            (true, session)
        }

        var capturedAccepted: Bool?
        var capturedSession: MCSession?

        // WHEN - invoking delegate method directly
        let dummyAdvertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: MultiPeerServices.edge.rawValue)
        sut.advertiser(dummyAdvertiser, didReceiveInvitationFromPeer: peer, withContext: nil) { accepted, session in
            capturedAccepted = accepted
            capturedSession = session
        }

        // THEN - handler receives true and same session, and log captured
        XCTAssertEqual(capturedAccepted, true) // swiftlint:disable:this xct_specific_matcher
        XCTAssertIdentical(capturedSession, session)
        assertLogsContain("didReceiveInvitationFromPeer", in: nodeManager)
        assertLogsContain(MultiPeerServices.edge.rawValue, in: nodeManager)
    }

    func testDidNotStartAdvertisingPeerResetsCallsClosureAndLogs() throws {
        // GIVEN - start and capture error
        struct TestError: Error, Equatable { let message: String }
        let expectedError = TestError(message: "boom")

        var capturedError: Error?
        sut.didNotStartAdvertising = { error in
            capturedError = error
        }

        sut.start() // set isAdvertising true

        // WHEN - invoke delegate error callback
        let dummyAdvertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: MultiPeerServices.edge.rawValue)
        sut.advertiser(dummyAdvertiser, didNotStartAdvertisingPeer: expectedError)

        // THEN - isAdvertising false, closure captured error, and log captured
        XCTAssertFalse(sut.isAdvertising)
        XCTAssertEqual(capturedError?.localizedDescription, expectedError.localizedDescription)
        assertLogsContain("didNotStartAdvertisingPeer error:", in: nodeManager)
        assertLogsContain(MultiPeerServices.edge.rawValue, in: nodeManager)
    }
}

// MARK: - Helpers
private extension MultiPeerAdvertiserTests {
    func makePeer(_ name: String = "TestPeer") -> MCPeerID {
        MCPeerID(displayName: name)
    }

    func makeSession(peer: MCPeerID) -> MCSession {
        MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
    }

    func assertLogsContain(_ message: String, in mock: MockNodeAdvertiser, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(mock.logs.isEmpty, "Expected logs to be non-empty; ensure MultiPeerAdvertiser is using injected nodeManager", file: file, line: line)
        XCTAssertTrue(mock.logs.contains(where: { $0.contains(message) }), "Expected logs to contain: \(message)", file: file, line: line)
    }
}
