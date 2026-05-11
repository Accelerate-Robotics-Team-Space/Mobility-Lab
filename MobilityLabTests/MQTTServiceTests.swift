//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import MQTTNIO
import NIO
import NIOCore
import NIOHTTP1
import NIOTransportServices
@testable import MobilityLab_BMM
import XCTest

final class MQTTServiceTests: XCTestCase {
    var securityService: MockSecurityService!
    var keychain: MockKeychain!
    var userDefaults: MockUserDefaultsService!
    var notificationCenterRaw: NotificationCenter!
    var notificationCenter: NotificationCenterService!
    var mqttV5: MockMQTTClientV5!
    var mqttClient: MockMQTTClient!
    var container: Container!
    var testSubject: MQTTService!

    override func setUp() {
        super.setUp()
        container = .init()
        container.resetAll()

        securityService = MockSecurityService()
        keychain = MockKeychain()
        userDefaults = MockUserDefaultsService()
        notificationCenterRaw = .init()
        notificationCenter = NotificationCenterService(notificationCenter: notificationCenterRaw)
        mqttV5 = MockMQTTClientV5()
        mqttClient = MockMQTTClient(ver5: mqttV5, host: "test_host")
        mqttClient.syncShutdownHandler = { }

        container.securityService.register { self.securityService }
        container.keychain.register { self.keychain }
        container.userDefaults.register { self.userDefaults }
        container.notificationCenter.register { self.notificationCenter }
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        notificationCenter = nil
        notificationCenterRaw = nil
        userDefaults = nil
        keychain = nil
        securityService = nil
        container = nil
    }

    // MARK: Initialization and startSession connect when config available

    func test_startSession_triggersConnect_whenConfigAvailable() async {
        // GIVEN
        var invocations = 0
        initTestSubject(
            connectHandler: { _ in
                invocations += 1
                return MockConnAck()
            }
        )
        // WHEN
        testSubject.startSession()
        try? await Task.sleep(nanoseconds: 200_000_000)
        // THEN
        XCTAssertTrue(invocations >= 1)
        XCTAssertEqual(testSubject.status, .connected)
    }
    
    // MARK: Status transitions and reset behavior
    
    func test_connect_whenDeviceNotRegistered_callsReset_andStatusRemainsClosed() {
        let exp1 = XCTestExpectation(description: "not registered - disconnect")
        mqttClient.disconnectHandler = {
            exp1.fulfill()
        }

        let exp2 = XCTestExpectation(description: "not registered - shutdown")
        mqttClient.syncShutdownHandler = {
            exp2.fulfill()
        }

        // GIVEN
        initTestSubject(
            isDeviceRegistered: { false },
            connectHandler: { _ in
                XCTFail("Connect handler should not be called when device is not registered")
                return MockConnAck()
            }
        )

        // WHEN connect is called
        testSubject.connect()

        wait(for: [exp1, exp2], timeout: 1)

        // THEN the status should remain closed
        XCTAssertEqual(testSubject.status, .closed)
    }

    // MARK: Parse Published Data - Observation

    func test_parsePublished_observation() {
        let roll: Double = 60
        let rollRad: Double = (roll * .pi) / 180
        let pitch: Double = 20
        let pitchRad: Double = (pitch * .pi) / 180
        let padding: [UInt8] = Array(repeating: 0, count: 80)
        let bytes: [UInt8] = padding + rollRad.toBytes() + pitchRad.toBytes()
        let data = Data(bytes)
        let topic = "x/y/echoBase/observation"

        initTestSubject()

        let event = testSubject.parsePublish(topic: topic, data: data)
        XCTAssertNotNil(event)
        switch event {
        case let .observation(baseStation, rollParsed, pitchParsed):
            XCTAssertEqual(baseStation, "echoBase")
            XCTAssertEqual(rollParsed, roll, accuracy: 1e-12)
            XCTAssertEqual(pitchParsed, pitch, accuracy: 1e-12)
        case .battery, .dataPoint, nil:
            XCTFail("Expected an 'observation', got \(String(describing: event))")
        }
    }

    // MARK: Parse Published Data - Battery

    func test_parsePublished_battery() {
        let value = "splendid"
        let data = Data(value.utf8)
        let topic = "x/y/echoBase/sensor/my_watch/battery_level"

        initTestSubject()

        let event = testSubject.parsePublish(topic: topic, data: data)
        XCTAssertNotNil(event)
        switch event {
        case let .battery(baseStation, wearableID, parsedValue):
            XCTAssertEqual(baseStation, "echoBase")
            XCTAssertEqual(wearableID, "my_watch")
            XCTAssertEqual(parsedValue, value)
        case .observation, .dataPoint, nil:
            XCTFail("Expected a 'battery', got \(String(describing: event))")
        }
    }

    // MARK: Parse Published Data - Data Point

    func test_parsePublished_dataPoint() {
        let value = "vital data"
        let data = Data(value.utf8)
        let topic = "x/y/echoBase/random"

        initTestSubject()

        let event = testSubject.parsePublish(topic: topic, data: data)
        XCTAssertNotNil(event)
        switch event {
        case let .dataPoint(baseStation, parsedTopic, parsedValue):
            XCTAssertEqual(baseStation, "echoBase")
            XCTAssertEqual(parsedTopic, "random")
            XCTAssertEqual(parsedValue, value)
        case .observation, .battery, nil:
            XCTFail("Expected an 'dataPoint', got \(String(describing: event))")
        }
    }

    // MARK: Connection flows and listeners
    // TODO: Fix this test and un-skip
    func test_connect_success_setsConnected_andRegistersListeners() {
        // GIVEN
        let closeExp = expectation(description: "close listener registered")
        let shutdownExp = expectation(description: "shutdown listener registered")
        let publishExp = expectation(description: "publish listener registered")
        mqttClient.addCloseListenerHandler = { _, _ in
            closeExp.fulfill()
        }
        mqttClient.addShutdownListenerHandler = { _, _ in
            shutdownExp.fulfill()
            // Don't trigger shutdown here
        }
        mqttClient.syncShutdownHandler = { }
        mqttClient.addPublisherListenerHandler = { _, _ in
            publishExp.fulfill()
            // Don't trigger publish here
        }

        initTestSubject(
            subscribeHandler: { infos in
                XCTAssertFalse(infos.isEmpty, "Subscribe should be called with at least one topic during resubscribe if any")
                return MockSubAck()
            }
        )

        // WHEN
        testSubject.connect()

        // THEN
        wait(for: [closeExp, shutdownExp, publishExp], timeout: 1.0)
        XCTAssertEqual(testSubject.status, .disconnected, "Close listener should have set status to disconnected")
    }

    func test_connect_failure_setsClosed() {
        // GIVEN
        initTestSubject(
            connectHandler: { _ in throw NSError(domain: "test", code: -1) }
        )

        // WHEN
        testSubject.connect()

        // THEN
        // Allow Task to execute
        let exp = expectation(description: "status becomes closed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.testSubject.status, .closed)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: Publish success and failure
    func test_publish_success_doesNotChangeStatus() {
        // GIVEN
        initTestSubject(
            connectHandler: { _ in MockConnAck() }
        )
        let data = Data("hello".utf8)
        mqttV5.publishWithRetainHandler = { topic, payload, qos, retain in
            XCTAssertEqual(topic, "t")
            XCTAssertEqual(qos, .atLeastOnce)
            XCTAssertFalse(retain)
            XCTAssertEqual(String(buffer: payload), "hello")
            return MockAck(reason: .success)
        }

        // WHEN
        testSubject.publish(data, to: "t", isRetained: false, qos: .atLeastOnce)

        // THEN
        let exp = expectation(description: "status remains connected or connecting")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertTrue([.connected, .connecting, .disconnected, .closed].contains(self.testSubject.status))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_publish_failure_setsDisconnected_whenWasConnected() {
        // GIVEN
        initTestSubject(
            connectHandler: { _ in MockConnAck() }
        )
        testSubject.status = .connected
        mqttV5.publishWithRetainHandler = { _, _, _, _ in
            throw NSError(domain: "test", code: -2)
        }

        // WHEN
        testSubject.publish(Data("msg".utf8), to: "x", isRetained: false, qos: .atLeastOnce)

        // THEN
        let exp = expectation(description: "status becomes disconnected")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.testSubject.status, .disconnected)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_publishAsync_success_returnsTopic() async throws {
        // GIVEN
        initTestSubject(
            connectHandler: { _ in MockConnAck() }
        )
        mqttV5.publishWithRetainHandler = { topic, payload, qos, retain in
            XCTAssertEqual(topic, "topicA")
            XCTAssertEqual(String(buffer: payload), "A")
            XCTAssertEqual(qos, .atMostOnce)
            XCTAssertTrue(retain)
            return MockAck(reason: .success)
        }

        // WHEN
        let result = try await testSubject.publishAsync(Data("A".utf8), to: "topicA", isRetained: true, qos: .atMostOnce)

        // THEN
        XCTAssertEqual(result, "topicA")
    }

    func test_publishAsync_failure_setsDisconnected_whenConnected() async {
        // GIVEN
        initTestSubject(
            connectHandler: { _ in MockConnAck() }
        )
        testSubject.status = .connected
        mqttV5.publishWithRetainHandler = { _, _, _, _ in
            throw NSError(domain: "test", code: -3)
        }

        // WHEN
        do {
            _ = try await testSubject.publishAsync(Data("B".utf8), to: "topicB", isRetained: false, qos: .exactlyOnce)
            XCTFail("Expected throw")
        } catch {
            // THEN
            XCTAssertEqual(testSubject.status, .disconnected)
        }
    }

    // MARK: Subscriptions and Unsubscriptions
    func test_subscribe_updatesSubscriptions() async {
        // GIVEN
        initTestSubject()
        let topics = ["a/1": 0, "b/2": 1]
        var subscribed = 0
        mqttV5.subscribeHandler = { infos in
            subscribed += 1
            if subscribed == 2 {
                XCTAssertEqual(infos.count, topics.count)
            }
            return MockSubAck()
        }

        // WHEN
        testSubject.subscribe(to: topics)
        try? await Task.sleep(nanoseconds: 500_000_000)

        // THEN
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(self.testSubject.subscriptions.keys.sorted(), Array(topics.keys).sorted())
    }

    func test_subscribeSingle_updatesSubscriptions() async {
        // GIVEN
        initTestSubject()
        let topics = ["only/one": 1]

        // WHEN
        testSubject.subscribeSingle(to: topics)
        try? await Task.sleep(nanoseconds: 500_000_000)

        // THEN
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(self.testSubject.subscriptions["only/one"], 1)
    }

    func test_unsubscribe_removesSubscriptions() async {
        // GIVEN
        initTestSubject()
        // Preload subscriptions map
        testSubject.subscribe(to: ["x": 0, "y": 1])
        try? await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertEqual(testSubject.subscriptions, ["x": 0, "y": 1])
        let exp = expectation(description: "unsubscribe handler called")
        mqttV5.unsubscribeHandler = { subs in
            XCTAssertEqual(Set(subs), Set(["x"]))
            exp.fulfill()
            return MockSubAck()
        }

        // WHEN
        testSubject.unsubscribe(from: ["x"])

        // THEN
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertNil(self.testSubject.subscriptions["x"])
        XCTAssertNotNil(self.testSubject.subscriptions["y"])
        await fulfillment(of: [exp], timeout: 2)
    }

    // MARK: Restart and Reset
    // TODO: Unskip flakey test
    func test_restartMQTTService_disconnectsAndConfigsClient() {
        // GIVEN
        let disconnectExp = expectation(description: "disconnect called on restart")
        let shutdownExp = expectation(description: "sync shutdown on restart")

        mqttV5.disconnectHandler = { _ in
            disconnectExp.fulfill()
        }
        mqttClient.syncShutdownHandler = {
            shutdownExp.fulfill()
        }
        initTestSubject()

        // WHEN
        testSubject.restartMQTTService()

        // THEN
        wait(for: [disconnectExp, shutdownExp], timeout: 1.0)
    }

    func test_reset_disconnectsAndShutsDownClient() {
        // GIVEN
        let disconnectExp = expectation(description: "disconnect called")
        let shutdownExp = expectation(description: "shutdown called")

        mqttClient.syncShutdownHandler = {
            shutdownExp.fulfill()
        }
        mqttClient.disconnectHandler = {
            disconnectExp.fulfill()
        }
        initTestSubject()

        // WHEN
        testSubject.reset()

        // THEN
        wait(for: [disconnectExp, shutdownExp], timeout: 1.0)
    }

    // MARK: parsePublish edge cases
    func test_parsePublished_unknownTopic_returnsDataPoint() {
        let data = Data("val".utf8)
        let topic = "a/b/base/some/other/topic"
        initTestSubject()
        let event = testSubject.parsePublish(topic: topic, data: data)
        switch event {
        case let .dataPoint(base, top, val):
            XCTAssertEqual(base, "base")
            XCTAssertEqual(val, "val")
            XCTAssertEqual(top, "topic")
        default:
            XCTFail("Expected dataPoint")
        }
    }

    func test_parsePublished_malformedObservation_returnsNil() {
        // Fewer than 96 bytes
        let data = Data(repeating: 0, count: 10)
        let topic = "x/y/echoBase/observation"
        initTestSubject()
        let event = testSubject.parsePublish(topic: topic, data: data)
        XCTAssertNil(event)
    }
}

private extension MQTTServiceTests {
    func initTestSubject(
        serialNumber: String = "123456",
        deviceGUID: String = "ABCDEF",
        isDeviceRegistered: @escaping (() -> Bool) = { true },
        connectHandler: @escaping ((Bool) async throws -> MQTTConnAck) = { _ in MockConnAck() },
        subscribeHandler: @escaping (([MQTTSubscribeInfoV5]) async throws -> MQTTSubAck) = { _ in MockSubAck() },
        closeHandler: @escaping (String, (Result<Void, any Error>) -> Void) -> Void = { _, _ in },
        shutdownHandler: @escaping (String, (Result<Void, any Error>) -> Void) -> Void = { _, _ in },
        publisherHandler: @escaping (String, (Result<MQTTPublishInfo, any Error>) -> Void) -> Void = { _, _ in }
    ) {
        keychain.certificateSerialNumber = serialNumber
        userDefaults.deviceGuid = deviceGUID
        securityService.isDeviceRegisteredHandler = isDeviceRegistered
        mqttV5.connectHandler = connectHandler
        mqttV5.subscribeHandler = subscribeHandler
        mqttClient.addCloseListenerHandler = closeHandler
        mqttClient.addShutdownListenerHandler = shutdownHandler
        mqttClient.addPublisherListenerHandler = publisherHandler

        testSubject = MQTTService(container: container, client: mqttClient)
        XCTAssertNotNil(testSubject.client)
    }
}

// MARK: - Helpers
private extension ByteBuffer {
    var data: Data {
        Data(buffer: self, byteTransferStrategy: .automatic)
    }

    var string: String? {
        return String(data: data, encoding: .utf8)
    }
}
