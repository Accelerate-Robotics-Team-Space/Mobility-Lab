// swiftlint:disable:this file_name
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import Logging
import MQTTNIO
import NIO
import NIOHTTP1
import NIOTransportServices

// swiftlint:disable large_tuple
typealias WillMQTTProp = (topicName: String, payload: ByteBuffer, qos: MQTTQoS, retain: Bool, properties: MQTTProperties)
typealias WillMQTTNoProp = (topicName: String, payload: ByteBuffer, qos: MQTTQoS, retain: Bool)
// swiftlint:enable large_tuple
typealias AuthMQTT = (MQTTAuthV5, any EventLoop) -> EventLoopFuture<MQTTAuthV5>
typealias Block = () -> Void

// MARK: - MQTT NIO V5 Client
protocol MQTTV5Protocol {
    func publish(to topicName: String, payload: ByteBuffer, qos: MQTTQoS, retain: Bool, properties: MQTTProperties) async throws -> MQTTAckV5?
    func publish(to topicName: String, payload: ByteBuffer, qos: MQTTQoS, retain: Bool) async throws -> MQTTAck?
    func publish(to topicName: String, payload: ByteBuffer, qos: MQTTQoS) async throws -> MQTTAck?
    func subscribe(to subscriptions: [MQTTSubscribeInfoV5], properties: MQTTProperties) async throws -> MQTTSubackV5
    func subscribe(to subscriptions: [MQTTSubscribeInfoV5]) async throws -> MQTTSubAck
    func unsubscribe(from subscriptions: [String], properties: MQTTProperties) async throws -> MQTTSubackV5
    func unsubscribe(from subscriptions: [String]) async throws -> MQTTSubAck
    func disconnect(properties: MQTTProperties) async throws
    func disconnect() async throws
    @discardableResult func connect(cleanStart: Bool, properties: MQTTProperties, will: WillMQTTProp?, authWorkflow: AuthMQTT?) async throws -> MQTTConnackV5
    @discardableResult func connect(cleanStart: Bool) async throws -> MQTTConnAck
}

// MQTT NIO V5 Client Default implementations
extension MQTTV5Protocol {
    func disconnect() async throws {
        try await disconnect(properties: MQTTProperties())
    }

    func unsubscribe(from subscriptions: [String]) async throws -> MQTTSubAck {
        try await unsubscribe(from: subscriptions, properties: MQTTProperties())
    }

    func subscribe(to subscriptions: [MQTTSubscribeInfoV5]) async throws -> MQTTSubAck {
        try await subscribe(to: subscriptions, properties: MQTTProperties())
    }

    func publish(to topicName: String, payload: ByteBuffer, qos: MQTTQoS) async throws -> MQTTAck? {
        try await publish(to: topicName, payload: payload, qos: qos, retain: false, properties: MQTTProperties())
    }

    func publish(to topicName: String, payload: ByteBuffer, qos: MQTTQoS, retain: Bool) async throws -> MQTTAck? {
        try await publish(to: topicName, payload: payload, qos: qos, retain: retain, properties: MQTTProperties())
    }

    func connect(cleanStart: Bool) async throws -> MQTTConnAck {
        try await connect(cleanStart: cleanStart, properties: MQTTProperties(), will: nil, authWorkflow: nil)
    }
}

// MARK: - MQTT NIO MQTTConnackV5 Protocol
// The MQTTNIO MQTTConnackV5 has no public initialiser, so is untestable.
// This makes the `connect(cleanStart:)` testable with a mock ConnAck
protocol MQTTConnAck {
    var sessionPresent: Bool { get }
    var reason: MQTTReasonCode { get }
    var properties: MQTTProperties { get }
}

protocol MQTTSubAck {
    var reasons: [MQTTReasonCode] { get }
    var properties: MQTTProperties { get }
}

protocol MQTTAck {
    var reason: MQTTReasonCode { get }
    var properties: MQTTProperties { get }
}

// MARK: - MQTT NIO Client
protocol MQTTClientProtocol: AnyObject {
    var host: String { get }
    var ver5: any MQTTV5Protocol { get }
    func disconnect() async throws
    func addCloseListener(named name: String, _ listener: @escaping (Result<Void, any Error>) -> Void)
    func addShutdownListener(named name: String, _ listener: @escaping (Result<Void, any Error>) -> Void)
    func addPublishListener(named name: String, _ listener: @escaping (Result<MQTTPublishInfo, any Error>) -> Void)
    func syncShutdownGracefully() throws
    func connect(cleanSession: Bool) async throws
}

// MARK: - MQTT NIO Conformance
extension MQTTNIO.MQTTConnackV5: MQTTConnAck { }
extension MQTTNIO.MQTTSubackV5: MQTTSubAck { }
extension MQTTNIO.MQTTAckV5: MQTTAck { }
extension MQTTNIO.MQTTClient.V5: MQTTV5Protocol { }
extension MQTTNIO.MQTTClient: MQTTClientProtocol {
    var ver5: MQTTV5Protocol {
        self.v5
    }

    func connect(cleanSession: Bool) async throws {
        _ = try await self.connect(cleanSession: cleanSession).get()
    }
}

// MARK: - Sensor Suite MQTT Service Delegate
protocol MQTTDelegate: AnyObject {
    func update(from baseStation: String, rollAngle: Double, pitchAngle: Double)
    func updateDataPoint(topic: String, from baseStation: String, with: String)
    func updateWearableBatteryLvl(from baseStation: String, wearableId: String, value: String)
}

// MARK: - Sensor Suite MQTT Service Protocol
protocol MQTTServiceProtocol: AnyObject {
    var subscriptions: [String: Int] { get }
    var subscriptionsPublisher: Published<[String: Int]>.Publisher { get }
    var delegate: MQTTDelegate? { get set }
    var status: MQTTSessionStatus { get set }
    var statusPublisher: Published<MQTTSessionStatus>.Publisher { get }
    func startSession()
    func connect()
    func connect(freshSession: Bool)
    func resubscribe()
    func executeOnConnection(closure: @escaping () -> Void)
    func disconnect()
    func disconnect(result: ((Result<Void, Error>) -> Void)?)
    func reset()
    func publish(_ someData: Data, to topicStr: String, isRetained: Bool, qos: MQTTQosLevel)
    func publish(_ someData: Data, to topicStr: String, isRetained: Bool, qos: MQTTQosLevel, result: ((Result<String, Error>) -> Void)?)
    func subscribe(to topicDict: [String: Int])
    func subscribe(to topicDict: [String: Int], result: ((Result<Void, Error>) -> Void)?)
    func subscribe<T: TopicStructurable>(to topics: [T])
    func subscribe<T: TopicStructurable>(to topics: [T], result: ((Result<Void, Error>) -> Void)?)
    func subscribeSingle(to topicDict: [String: Int])
    func subscribeSingle(to topicDict: [String: Int], result: ((Result<Void, Error>) -> Void)?)
    func unsubscribe(from topicsArr: [String])
    func unsubscribe(from topicsArr: [String], result: ((Result<Void, Error>) -> Void)?)
    func unsubscribe<T: TopicStructurable>(from topics: [T])
    func unsubscribe<T: TopicStructurable>(from topics: [T], result: ((Result<Void, Error>) -> Void)?)
    func restartMQTTService()
    func publishAsync(_ data: Data, to topic: String, isRetained: Bool, qos: MQTTQosLevel) async throws -> String
}
