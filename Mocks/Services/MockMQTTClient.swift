//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import MQTTNIO
import NIO
import NIOCore
import NIOHTTP1
import NIOTransportServices
@testable import MobilityLab_BMM

struct MockConnAck: MQTTConnAck {
    let sessionPresent: Bool
    let reason: MQTTNIO.MQTTReasonCode
    let properties: MQTTNIO.MQTTProperties

    init(
        sessionPresent: Bool = true,
        reason: MQTTNIO.MQTTReasonCode = .grantedQoS1,
        properties: MQTTNIO.MQTTProperties = MQTTProperties()
    ) {
        self.sessionPresent = sessionPresent
        self.reason = reason
        self.properties = properties
    }
}

struct MockSubAck: MQTTSubAck {
    let reasons: [MQTTReasonCode]
    let properties: MQTTProperties

    init(reasons: [MQTTReasonCode] = [], properties: MQTTProperties = MQTTProperties()) {
        self.reasons = reasons
        self.properties = properties
    }
}

struct MockAck: MQTTAck {
    let reason: MQTTReasonCode
    let properties: MQTTProperties

    init(reason: MQTTReasonCode, properties: MQTTProperties = MQTTProperties()) {
        self.reason = reason
        self.properties = properties
    }
}

final class MockMQTTClientV5: MQTTV5Protocol {
    // These 'full' functions basically untestable as the MQTTNIO Connacks have no public initialisers. Only provided for completeness.
    var connectFullHandler: ((Bool, MQTTProperties, WillMQTTProp?, AuthMQTT?) async throws -> MQTTConnackV5)?
    var unsubscribeFullHandler: (([String], MQTTProperties) async throws -> MQTTSubackV5)?
    var subscribeFullHandler: (([MQTTSubscribeInfoV5], MQTTProperties) async throws -> MQTTSubackV5)?
    var publishFullHandler: ((String, ByteBuffer, MQTTQoS, Bool, MQTTProperties) async throws -> MQTTAckV5?)?

    var connectHandler: ((Bool) async throws -> MQTTConnAck)?
    var disconnectHandler: ((MQTTProperties) async throws -> Void)?
    var unsubscribeHandler: (([String]) async throws -> MQTTSubAck)?
    var subscribeHandler: (([MQTTSubscribeInfoV5]) async throws -> MQTTSubAck)?
    var publishWithRetainHandler: ((String, ByteBuffer, MQTTQoS, Bool) async throws -> MQTTAck?)?
    var publishHandler: ((String, ByteBuffer, MQTTQoS) async throws -> MQTTAck?)?

    // MARK: Untestable implementations
    // These 'full' functions basically untestable as the MQTTNIO Connacks have no public initialisers. Only provided for completeness.
    func connect(cleanStart: Bool, properties: MQTTProperties, will: WillMQTTProp?, authWorkflow: AuthMQTT?) async throws -> MQTTConnackV5 {
        guard let connectFullHandler else {
            fatalError("connectFullHandler must be set")
        }
        return try await connectFullHandler(cleanStart, properties, will, authWorkflow)
    }

    func publish(to topicName: String, payload: ByteBuffer, qos: MQTTQoS, retain: Bool, properties: MQTTProperties) async throws -> MQTTAckV5? {
        guard let publishFullHandler else {
            fatalError("publishFullHandler must be set")
        }
        return try await publishFullHandler(topicName, payload, qos, retain, properties)
    }

    func unsubscribe(from subscriptions: [String], properties: MQTTProperties) async throws -> MQTTSubackV5 {
        guard let unsubscribeFullHandler else {
            fatalError("unsubscribeFullHandler must be set")
        }
        return try await unsubscribeFullHandler(subscriptions, properties)
    }

    // MARK: Start of testable implementations
    func connect(cleanStart: Bool) async throws -> MQTTConnAck {
        guard let connectHandler else {
            fatalError("connectHandler must be set")
        }
        return try await connectHandler(cleanStart)
    }

    func disconnect(properties: MQTTProperties) async throws {
        guard let disconnectHandler else {
            fatalError("disconnectHandler must be set")
        }
        try await disconnectHandler(properties)
    }

    func unsubscribe(from subscriptions: [String]) async throws -> MQTTSubAck {
        guard let unsubscribeHandler else {
            fatalError("unsubscribeHandler must be set")
        }
        return try await unsubscribeHandler(subscriptions)
    }

    func subscribe(to subscriptions: [MQTTSubscribeInfoV5], properties: MQTTProperties) async throws -> MQTTSubackV5 {
        guard let subscribeFullHandler else {
            fatalError("subscribeFullHandler must be set")
        }
        return try await subscribeFullHandler(subscriptions, properties)
    }

    func subscribe(to subscriptions: [MQTTSubscribeInfoV5]) async throws -> MQTTSubAck {
        guard let subscribeHandler else {
            fatalError("subscribeHandler must be set")
        }
        return try await subscribeHandler(subscriptions)
    }

    func publish(to topicName: String, payload: ByteBuffer, qos: MQTTQoS) async throws -> MQTTAck? {
        guard let publishHandler else {
            fatalError("publishHandler must be set")
        }
        return try await publishHandler(topicName, payload, qos)
    }

    func publish(to topicName: String, payload: ByteBuffer, qos: MQTTQoS, retain: Bool) async throws -> MQTTAck? {
        guard let publishWithRetainHandler else {
            fatalError("publishWithRetainHandler must be set")
        }
        return try await publishWithRetainHandler(topicName, payload, qos, retain)
    }
}

final class MockMQTTClient: MQTTClientProtocol {
    var host: String
    var ver5: MQTTV5Protocol
    var connectHandler: ((Bool) async throws -> Void)?
    var disconnectHandler: (() async throws -> Void)?
    var addCloseListenerHandler: ((String, (Result<Void, any Error>) -> Void) -> Void)?
    var addShutdownListenerHandler: ((String, (Result<Void, any Error>) -> Void) -> Void)?
    var addPublisherListenerHandler: ((String, (Result<MQTTPublishInfo, any Error>) -> Void) -> Void)?
    var syncShutdownHandler: (() throws -> Void)?

    init(ver5: MQTTV5Protocol, host: String) {
        self.ver5 = ver5
        self.host = host
    }

    func connect(cleanSession: Bool) async throws {
        guard let connectHandler else {
            fatalError("connectHandler must be set")
        }
        return try await connectHandler(cleanSession)
    }

    func disconnect() async throws {
        guard let disconnectHandler else {
            fatalError("disconnectAsyncHandler must be set")
        }
        try await disconnectHandler()
    }

    func addCloseListener(named name: String, _ listener: @escaping (Result<Void, any Error>) -> Void) {
        guard let addCloseListenerHandler else {
            fatalError("addCloseListenerHandler must be set")
        }
        addCloseListenerHandler(name, listener)
    }

    func addShutdownListener(named name: String, _ listener: @escaping (Result<Void, any Error>) -> Void) {
        guard let addShutdownListenerHandler else {
            fatalError("addShutdownListenerHandler must be set")
        }
        addShutdownListenerHandler(name, listener)
    }

    func addPublishListener(named name: String, _ listener: @escaping (Result<MQTTPublishInfo, any Error>) -> Void) {
        guard let addPublisherListenerHandler else {
            fatalError("addPublisherListenerHandler must be set")
        }
        addPublisherListenerHandler(name, listener)
    }

    func syncShutdownGracefully() throws {
        guard let syncShutdownHandler else {
            fatalError("syncShutdownHandler must be set")
        }
        try syncShutdownHandler()
    }
}
