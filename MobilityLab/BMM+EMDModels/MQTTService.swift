//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import Logging
import MQTTNIO
import NIO
import NIOHTTP1
import NIOTransportServices
import UIKit

#if BMM
extension Container {
    var mqttService: Factory<MQTTServiceProtocol> {
        self { MQTTService() }.cached
    }
}
#endif

final class MQTTService: MQTTServiceProtocol {
    enum PublishEvent {
        case observation(baseStation: String, roll: Double, pitch: Double)
        case battery(baseStation: String, wearableId: String, value: String)
        case dataPoint(baseStation: String, topic: String, value: String)
    }

    #if EMD
    static let shared: MQTTServiceProtocol = MQTTService()
    private var keychainService = Keychain.shared
    private var userDefaults = UserDefaults.standard
    private let notificationCenter: NotificationCenterServiceProtocol = NotificationCenterService.shared
    #else
    private let keychainService: KeychainProtocol
    private let userDefaults: BMMUserDefaultsServiceProtocol
    private let notificationCenter: NotificationCenterServiceProtocol
    #endif
    static let statusNote = Notification.Name("Publisher_Subscriber_Client.status_updated")
    static let subscriptionNote = NSNotification.Name("Publisher_Subscriber_Client.subscription_updated")
    static let eventLoopGroup = NIOTSEventLoopGroup()

    private(set) var client: MQTTClientProtocol?
    private let injectedClient: MQTTClientProtocol?

    private let container: Container
    private var securityService: SecurityServiceProtocol { container.securityService.resolve() }

    private let subsQueue = DispatchQueue(label: "MQTTSubscriptionsQueue", qos: .default)
    private let mqttServiceQueue = DispatchQueue(label: "MQTTServiceQueue")
    private var executeOnConnectionList: [Block] = []
    @Published private(set) var subscriptions: [String: Int] = [:] {
        didSet {
            // TODO: Replace Notification Center use with Combine Publisher
            notificationCenter.post(name: MQTTService.subscriptionNote, object: nil, userInfo: subscriptions)
        }
    }

    var subscriptionsPublisher: Published<[String: Int]>.Publisher {
        $subscriptions
    }

    weak var delegate: MQTTDelegate?

    // MARK: - Computed Var's
    @Published var status: MQTTSessionStatus = .closed {
        didSet {
            logger.debug("BMM MQTT status: \(status)")
            Task { @MainActor [weak self] in
                self?.notificationCenter.post(name: MQTTService.statusNote, object: nil)
            }
            if status == .connected {
                mqttServiceQueue.async {
                    self.executeOnConnectionList.forEach({ $0() })
                    self.executeOnConnectionList.removeAll()
                    self.resubscribe()
                }
            } else if status == .closed || status == .disconnected {
                guard securityService.isDeviceRegistered else {
                    reset()
                    return
                }
                DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.reconnect()
                }
            }
        }
    }

    var statusPublisher: Published<MQTTSessionStatus>.Publisher {
        $status
    }

    // MARK: - Init
    init(container: Container = .shared, client: MQTTClientProtocol? = nil) {
        self.container = container
        #if BMM
        self.userDefaults = container.userDefaults.resolve()
        self.keychainService = container.keychain.resolve()
        self.notificationCenter = container.notificationCenter.resolve()
        #endif
        if let client {
            self.client = client
            self.injectedClient = client
        } else {
            self.injectedClient = nil
            guard let config = connectionConfig() else {
                return
            }
            self.client = defaultClient(config)
        }
        startSession()
    }

    deinit {
        try? client?.syncShutdownGracefully()
    }

    func startSession() {
        connect()
    }

    private func configClient() {
        try? client?.syncShutdownGracefully()
        if let injectedClient {
            self.client = injectedClient
        } else {
            guard let config = connectionConfig() else {
                return
            }
            self.client = defaultClient(config)
        }
    }

    private func defaultClient(_ configuration: MQTTClient.Configuration) -> MQTTClient {
        MQTTClient(
            host: userDefaults.host,
            port: NetworkingConstants.mqttPort,
            identifier: userDefaults.defaultingBaseStationFromApple,
            eventLoopGroupProvider: .shared(Self.eventLoopGroup),
            logger: mqttLogger(),
            configuration: configuration
        )
    }

    // MARK: - Connect/Disconnect
    /// Connects to the MQTT Broker
    /// - Parameter result: Result of connection
    func connect() {
        connect(freshSession: true)
    }

    func connect(freshSession: Bool) {
        guard securityService.isDeviceRegistered else {
            reset()
            return
        }

        guard status != .connected, status != .connecting else {
            return
        }

        if client == nil { configClient() }
        logger.debug(" BMM MQTT try to connect")
        status = .connecting
        Task { [weak self] in
            do {
                _ = try await self?.client?.ver5.connect(cleanStart: freshSession)
                self?.status = .connected
                self?.client?.addCloseListener(named: "DisconnectionEar") { [weak self] _ in
                    Task { [weak self] in
                        self?.status = .disconnected
                    }
                }
                self?.client?.addShutdownListener(named: "ShutdownEar") { [weak self] _ in
                    Task { [weak self] in
                        self?.status = .closed
                    }
                }
                self?.client?.addPublishListener(named: "PublishEar") { [weak self] result in
                    Task { [weak self] in
                        guard let message = try? result.get() else {
                            return
                        }
                        self?.handlePublish(message)
                    }
                }
            } catch {
                self?.status = .closed
            }
        }
    }

    func resubscribe() {
        if status == .connected {
            var subs: [String: Int] = [:]
            subscriptions.forEach({ subs[$0.key] = $0.value })
            subscribe(to: subs)
        }
    }

    func executeOnConnection(closure: @escaping Block) {
        mqttServiceQueue.async {
            self.executeOnConnectionList.append(closure)
        }
    }

    /// Disconnects from the MQTT Broker
    /// - Parameter result: Result of the disconnection
    func disconnect() {
        disconnect(result: nil)
    }

    func disconnect(result: ((Result<Void, Error>) -> Void)?) {
        Task {
            do {
                try await client?.disconnect()
                self.log("Disconnected to MQTT host \(client?.host ?? "")")
                result?(.success)
            } catch {
                self.log("MQTT Disconnection failed with err: \(error.localizedDescription)")
                result?(.failure(error))
            }
        }
    }

    func reset() {
        Task {
            do {
                _ = try await client?.disconnect()
                try client?.syncShutdownGracefully()
                client = nil
            } catch {
                log("MQTT Disconnection error \(error.localizedDescription)")
            }
        }
    }

    private func reconnect() {
        guard securityService.isDeviceRegistered else {
            reset()
            return
        }
        guard status != .connected, status != .connecting else {
            return
        }
        Task {
            do {
                if client == nil {
                    connect(freshSession: false)
                } else {
                    status = .connecting
                    _ = try await client?.connect(cleanSession: false)
                    status = .connected
                    log("MQTT Reconnection successful")
                }
            } catch let error as MQTTError {
                self.log(error.localizedDescription)
                status = .disconnected
            } catch let error as NIOCore.ChannelError {
                self.log(error.localizedDescription)
                status = .disconnected
            } catch {
                self.log(error.localizedDescription)
                status = .disconnected
            }
        }
    }

    private func subscriptionsSet(key: String, value: Int) {
        subsQueue.async {
            self.subscriptions[key] = value
        }
    }

    private func handlePublish(_ message: MQTTPublishInfo) {
        let topic = message.topicName
        let data = Data(buffer: message.payload, byteTransferStrategy: .automatic)
        log("new Message coming in from topic: \(topic)")
        guard let event = parsePublish(topic: topic, data: data) else { return }
        DispatchQueue.main.async { [weak self] in
            switch event {
            case let .observation(baseStation, roll, pitch):
                self?.delegate?.update(from: baseStation, rollAngle: roll, pitchAngle: pitch)
            case let .battery(baseStation, wearableId, value):
                self?.delegate?.updateWearableBatteryLvl(from: baseStation, wearableId: wearableId, value: value)
            case let .dataPoint(baseStation, topic, value):
                self?.delegate?.updateDataPoint(topic: topic, from: baseStation, with: value)
            }
        }
    }

    func parsePublish(topic fullTopic: String, data: Data) -> PublishEvent? {
        let parts = fullTopic.components(separatedBy: "/")
        guard let topic = parts.last, parts.count >= 3 else {
            return nil
        }
        let baseStation = parts[2]
        if topic == "observation" {
            let byteArray = [UInt8](data)
            guard byteArray.count > 95 else {
                return nil
            }
            let rollBytes: [UInt8] = (80...87).map { byteArray[$0] }
            let rollRadians: Double = Double(rollBytes) ?? 0.0
            let rollDegrees = rollRadians * 180.0 / Double.pi
            let pitchBytes: [UInt8] = (88...95).map { byteArray[$0] }
            let pitchRadians: Double = Double(pitchBytes) ?? 0.0
            let pitchDegrees = pitchRadians * 180.0 / Double.pi
            return .observation(baseStation: baseStation, roll: rollDegrees, pitch: pitchDegrees)
        } else if parts.contains("sensor") && topic == "battery_level" {
            let value = String(decoding: data, as: UTF8.self)
            let wearableId = parts.count > 4 ? parts[4] : ""
            return .battery(baseStation: baseStation, wearableId: wearableId, value: value)
        } else {
            let value = String(decoding: data, as: UTF8.self)
            return .dataPoint(baseStation: baseStation, topic: topic, value: value)
        }
    }

    // MARK: - Publish
    /// Publish data to the MQTT Broker
    /// - Parameters:
    ///   - someData: Data to publish
    ///   - topicStr: Topic of data in string format
    ///   - isRetained: Specifies if the Will Message is to be Retained when it is published
    ///   - qos: Qualitie of service for msg delivery
    ///   - result: Result of the publication
    func publish(_ someData: Data, to topicStr: String, isRetained: Bool, qos: MQTTQosLevel) {
        publish(someData, to: topicStr, isRetained: isRetained, qos: qos, result: nil)
    }

    func publish(_ someData: Data, to topicStr: String, isRetained: Bool, qos: MQTTQosLevel, result: ((Result<String, Error>) -> Void)?) {
        Task {
            do {
                logger.debug("Publishing to topic \(topicStr), Data: " + String(decoding: someData, as: UTF8.self))
                _ = try await client?.ver5.publish(to: topicStr, payload: ByteBuffer(data: someData), qos: qos.toNIOQos(), retain: isRetained)
                result?(.success("Publish Success to topic \(topicStr)"))
            } catch {
                logger.warn("Error publishing to MQTT: \(error), topic: \(topicStr)")
                result?(.failure(error))
                if status == .connected {
                    status = .disconnected
                }
            }
        }
    }

    // MARK: - Publish
    /// Publish data to the MQTT Broker
    /// - Parameters:
    ///   - data: Data to publish
    ///   - topic: Topic of data in string format
    ///   - isRetained: Specifies if the Will Message is to be Retained when it is published
    ///   - qos: Qualitie of service for msg delivery
    /// - Returns: Result of the publication
    func publishAsync(_ data: Data, to topic: String, isRetained: Bool, qos: MQTTQosLevel) async throws -> String {
        do {
            logger.debug("Publishing data: " + String(decoding: data, as: UTF8.self))
            _ = try await client?.ver5.publish(to: topic, payload: ByteBuffer(data: data), qos: qos.toNIOQos(), retain: isRetained)
            return topic
        } catch {
            if status == .connected {
                status = .disconnected
            }
            throw error
        }
    }

    // MARK: - Subscription
    /// Subscribe to topic to recieve msg from the MQTT Broker when the topic is updated
    /// - Parameters:
    ///   - topicDict: Topics to subscribe too, is in the following format: [TopicStr: QosInt]
    ///   - result: The result of the subscription
    func subscribe(to topicDict: [String: Int]) {
        subscribe(to: topicDict, result: nil)
    }

    func subscribe(to topicDict: [String: Int], result: ((Result<Void, Error>) -> Void)?) {
        let info = topicDict.map({
            MQTTSubscribeInfoV5(topicFilter: $0.key, qos: MQTTQoS(rawValue: UInt8($0.value)) ?? .atLeastOnce)
        })

        Task {
            do {
                _ = try await client?.ver5.subscribe(to: info)
                topicDict.forEach({ self.subscriptionsSet(key: $0.key, value: $0.value) })
                self.log("Subscribed to topics: \(topicDict.keys.split(separator: ", "))")
                result?(.success)
            } catch {
                self.log("Subscription Error: \(error.localizedDescription)")
                result?(.failure(error))
            }
        }
    }
    
    /// Convenience method to subscribe to topic
    /// - Parameters:
    ///   - topics: Topics to subscribe too (has all necessary info to subscribe)
    ///   - result: The result of the subscription
    func subscribe<T: TopicStructurable>(to topics: [T]) {
        subscribe(to: topics, result: nil)
    }

    func subscribe<T: TopicStructurable>(to topics: [T], result: ((Result<Void, Error>) -> Void)?) {
        var topicsDict: [String: Int] = [:]
        topics.forEach({ topicsDict[$0.structure] = $0.qualityOfService.rawValue })
        subscribe(to: topicsDict)
    }
    
    /// if topicDict only contain 1 element
    func subscribeSingle(to topicDict: [String: Int]) {
        subscribeSingle(to: topicDict, result: nil)
    }

    func subscribeSingle(to topicDict: [String: Int], result: ((Result<Void, Error>) -> Void)?) {
        let info = topicDict.map({
            MQTTSubscribeInfoV5(topicFilter: $0.key, qos: MQTTQoS(rawValue: UInt8($0.value)) ?? .atLeastOnce)
        })
        Task {
            do {
                _ = try await client?.ver5.subscribe(to: info)
                topicDict.forEach({ self.subscriptionsSet(key: $0.key, value: $0.value) })
                self.log("Subscribed to topics: \(topicDict.keys.split(separator: ", "))")
                result?(.success)
            } catch {
                self.log("Subscription Error: \(error.localizedDescription)")
                result?(.failure(error))
            }
        }
    }
    
    /// Unsubscribe to topic to STOP receiving msgs from the MQTT Broker when the topic is updated
    /// - Parameters:
    ///   - topicsArr: Topics to unsubscribe too, is in the following format: [TopicStr]
    ///   - result: The result of the unsubscription
    func unsubscribe(from topicsArr: [String]) {
        unsubscribe(from: topicsArr, result: nil)
    }

    func unsubscribe(from topicsArr: [String], result: ((Result<Void, Error>) -> Void)?) {
        Task {
            do {
                _ = try await client?.ver5.unsubscribe(from: topicsArr)
                topicsArr.forEach({ self.subscriptions.removeValue(forKey: $0) })
                self.log("Unsubscribed to topics: \(topicsArr.split(separator: ", "))")
                result?(.success)
            } catch {
                self.log("Unsubscription Error: \(error.localizedDescription)")
                result?(.failure(error))
            }
        }
    }
    
    /// Convenience method to unsubscribe to topic
    /// - Parameters:
    ///   - topics: Topics to unsubscribe too (has all necessary info to unsubscribe)
    ///   - result: The result of the unsubscription
    func unsubscribe<T: TopicStructurable>(from topics: [T]) {
        unsubscribe(from: topics, result: nil)
    }

    func unsubscribe<T: TopicStructurable>(from topics: [T], result: ((Result<Void, Error>) -> Void)?) {
        let topicsArr = topics.map({ $0.structure })
        Task {
            _ = try await client?.ver5.unsubscribe(from: topicsArr)
            topicsArr.forEach({ self.subscriptions.removeValue(forKey: $0) })
        }
    }

    /// Restart the MQTT Session with the new X-ATLAS-DEVICE-ID
    /// and X-ATLAS-DEVICE-CERTIFICATE from device registration
    func restartMQTTService() {
        Task {
            try? await self.client?.ver5.disconnect()
            configClient()
        }
    }
}

// MARK: - Extension (non-private for testing access on connectionConfig)
extension MQTTService {
    private func log(_ msg: String) {
        if NetworkingConstants.showMQTTLogs {
            logger.debug("🗣📲 \(msg)")
        }
    }

    private func mqttLogger() -> Logging.Logger {
        var logger = Logging.Logger(label: "EMD")
        #if DEBUG
        logger.logLevel = .trace
        #else
        logger.logLevel = .critical
        #endif
        return logger
    }

    func connectionConfig() -> MQTTClient.Configuration? {
        guard let deviceId = userDefaults.deviceGuid,
              let serialNumber = keychainService.certificateSerialNumber else {
            return nil
        }
        let headers = [
            ("X-ATLAS-DEVICE-ID", deviceId),
            ("X-ATLAS-DEVICE-CERTIFICATE", serialNumber),
        ]
        return MQTTClient.Configuration(
            version: .v5_0,
            timeout: .seconds(10),
            useSSL: NetworkingConstants.mqttTls,
            webSocketConfiguration: .init(
                urlPath: NetworkingConstants.mqttPath,
                initialRequestHeaders: HTTPHeaders(headers)
            )
        )
    }
}
