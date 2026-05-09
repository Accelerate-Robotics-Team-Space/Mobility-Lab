//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
@testable import MobilityLab_BMM
import XCTest

final class NodeManagerTests: XCTestCase {
    private var testSubject: NodeManager!
    private var container: Container!
    private var networkMonitor: MockNetworkMonitor!
    private var rawNotificationCenter: NotificationCenter!
    private var notificationCenter: NotificationCenterService!
    private var userDefaults: MockUserDefaultsService!
    private var keychain: MockKeychain!
    private var advertiser: MockMultiPeerAdvertiser!
    private var mqttServce: MockMQTTService!
    private var securityService: MockSecurityService!

    private let logInterval: TimeInterval = 1
    private let peerID: Int = 1

    override func setUp() {
        super.setUp()
        container = .init()
        container.resetAll()

        keychain = MockKeychain()
        securityService = MockSecurityService()
        networkMonitor = MockNetworkMonitor()
        advertiser = MockMultiPeerAdvertiser()
        rawNotificationCenter = NotificationCenter()
        notificationCenter = NotificationCenterService(notificationCenter: rawNotificationCenter)
        userDefaults = MockUserDefaultsService()
        mqttServce = MockMQTTService()

        userDefaults.incrementPeerIDHandler = { self.peerID }
        advertiser.startHandler = { }
        securityService.evaluateMeshCertsHandler = { _, result in
            result(.success(()))
        }

        container.networkMonitor.register { self.networkMonitor }
        container.notificationCenter.register { self.notificationCenter }
        container.userDefaults.register { self.userDefaults }
        container.mqttService.register { self.mqttServce }
        container.keychain.register { self.keychain }
        container.securityService.register { self.securityService }

        testSubject = NodeManager(container: container, logInterval: logInterval, advertiser: advertiser)
        container.nodeManager.register { self.testSubject }
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        mqttServce = nil
        userDefaults = nil
        notificationCenter = nil
        networkMonitor = nil
        rawNotificationCenter = nil
        securityService = nil
        keychain = nil
        container = nil
    }

    @MainActor
    func testStart() async {
        testSubject.start()
        try? await Task.sleep(nanoseconds: logInterval.nSec + 5_000)
        XCTAssertFalse(testSubject.logs.isEmpty)
        XCTAssertEqual(testSubject.logs.first, "🕸📲 Making Session with peer: \(UIDevice.current.name)_\(peerID)")
    }

    func testAddLog() async {
        let expected = "TestString"
        testSubject.addLog(expected)
        try? await Task.sleep(nanoseconds: logInterval.nSec + 18_000)
        XCTAssertFalse(testSubject.logs.isEmpty)
        XCTAssertEqual(testSubject.logs[optional: 1], expected)
    }

    func testTransmitConnected() async {
        networkMonitor.isConnected = true
        rawNotificationCenter.post(name: NetworkMonitor.connectionNote, object: nil)

        let transmitter = MultipeerTransmitter(
            topic: "topic/x/y/z",
            data: Data("AnyOldData".utf8),
            isRetained: true,
            qosLvl: .atLeastOnce
        )

        let exp = expectation(description: #function)
        var capturedResult: Result<(), Error>?
        testSubject.transmit(transmitter) { result in
            capturedResult = result
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: 1)
        switch capturedResult {
        case .success:
            XCTFail("Unexpected success, no peers defined")
        case .failure(let error):
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "MCSession")
            XCTAssertEqual(nsError.code, 2)
            XCTAssertEqual(nsError.userInfo.first?.value as? String, "Invalid peerIDs parameter.")
        case .none:
            XCTFail("Closure not called")
        }
    }

    func testTransmitNotConnected() async {
        networkMonitor.isConnected = false
        rawNotificationCenter.post(name: NetworkMonitor.disconnectionNote, object: nil)

        let transmitter = MultipeerTransmitter(
            topic: "topic/x/y/z",
            data: Data("AnyOldData".utf8),
            isRetained: true,
            qosLvl: .atLeastOnce
        )

        let exp = expectation(description: #function)
        var capturedResult: Result<(), Error>?
        testSubject.transmit(transmitter) { result in
            capturedResult = result
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: 1)
        switch capturedResult {
        case .success:
            XCTFail("Unexpected success, no peers defined")
        case .failure(let error):
            switch error {
            case NodeManager.NodeError.noProxyEdgePeer:
                XCTAssertTrue(true, "No Peers Defined")
            default:
                XCTFail("Unexpected error: \(error)")
            }
        case .none:
            XCTFail("Closure not called")
        }
    }

    func testConnection() {
        networkMonitor.isConnected = true
        advertiser.startHandler = {
            print("TODO")
        }
        rawNotificationCenter.post(name: NetworkMonitor.connectionNote, object: nil)

        XCTAssertNil(testSubject.proxy)
        XCTAssertNotNil(testSubject.edge)
    }

    func testDisconnection() {
        networkMonitor.isConnected = false
        rawNotificationCenter.post(name: NetworkMonitor.disconnectionNote, object: nil)

        XCTAssertNil(testSubject.edge)
        XCTAssertNotNil(testSubject.proxy)
    }
}
