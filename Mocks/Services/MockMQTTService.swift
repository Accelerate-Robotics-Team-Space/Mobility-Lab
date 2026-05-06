//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation
@testable import SensorSuite_BMM

final class MockMQTTService: MQTTServiceProtocol {
    var subscriptionsPublisher: Published<[String: Int]>.Publisher {
        $subscriptions
    }

    var statusPublisher: Published<MQTTSessionStatus>.Publisher {
        $status
    }

    @Published var subscriptions: [String: Int] = [:]

    var delegate: (any MQTTDelegate)?

    @Published var status: MQTTSessionStatus = .disconnected

    var startSessionHandler: (() -> Void)?
    var connectHandler: (() -> Void)?
    var connectFreshSessionHandler: ((Bool) -> Void)?
    var resubscribeHandler: (() -> Void)?
    var executeOnConnectionHandler: ((() -> Void) -> Void)?
    var disconnectHandler: (() -> Void)?
    var disconnectWithResultHandler: ((((Result<Void, any Error>) -> Void)?) -> Void)?
    var resetHandler: (() -> Void)?
    var publishHandler: ((Data, String, Bool, MQTTQosLevel) -> Void)?
    var publishAsyncHandler: ((Data, String, Bool, MQTTQosLevel) async throws -> String)?
    var publishWithResultHandler: ((Data, String, Bool, MQTTQosLevel, ((Result<String, any Error>) -> Void)?) -> Void)?
    var subscribeHandler: (([String: Int]) -> Void)?
    var subscribeWithResultHandler: (([String: Int], ((Result<Void, any Error>) -> Void)?) -> Void)?
    var subscribeTopicsHandler: (() -> Void)?
    var subscribeTopicsWithResultHandler: ((((Result<Void, any Error>) -> Void)?) -> Void)?
    var subscribeSingleHandler: (([String: Int]) -> Void)?
    var subscribeSingleWithResultHandler: (([String: Int], ((Result<Void, any Error>) -> Void)?) -> Void)?
    var unsubscribeHandler: (([String]) -> Void)?
    var unsubscribeWithResultHandler: (([String], ((Result<Void, any Error>) -> Void)?) -> Void)?
    var unsubscribeTopicsHandler: (() -> Void)?
    var unsubscribeTopicsWithResultHandler: ((((Result<Void, any Error>) -> Void)?) -> Void)?
    var restartMQTTServiceHandler: (() -> Void)?

    func startSession() {
        guard let startSessionHandler else {
            fatalError("startSessionHandler must be set")
        }
        startSessionHandler()
    }

    func connect() {
        guard let connectHandler else {
            fatalError("connectHandler must be set")
        }
        connectHandler()
    }

    func connect(freshSession: Bool) {
        guard let connectFreshSessionHandler else {
            fatalError("connectFreshSessionHandler must be set")
        }
        connectFreshSessionHandler(freshSession)
    }

    func resubscribe() {
        guard let resubscribeHandler else {
            fatalError("resubscribeHandler must be set")
        }
        resubscribeHandler()
    }

    func executeOnConnection(closure: @escaping () -> Void) {
        guard let executeOnConnectionHandler else {
            fatalError("executeOnConnectionHandler must be set")
        }
        executeOnConnectionHandler(closure)
    }

    func disconnect() {
        guard let disconnectHandler else {
            fatalError("disconnectHandler must be set")
        }
        disconnectHandler()
    }

    func disconnect(result: ((Result<Void, any Error>) -> Void)?) {
        guard let disconnectWithResultHandler else {
            fatalError("disconnectWithResultHandler must be set")
        }
        disconnectWithResultHandler(result)
    }

    func reset() {
        guard let resetHandler else {
            fatalError("resetHandler must be set")
        }
        resetHandler()
    }

    func publish(_ someData: Data, to topicStr: String, isRetained: Bool, qos: MQTTQosLevel) {
        guard let publishHandler else {
            fatalError("publishHandler must be set")
        }
        publishHandler(someData, topicStr, isRetained, qos)
    }

    func publishAsync(_ data: Data, to topic: String, isRetained: Bool, qos: MQTTQosLevel) async throws -> String {
        guard let publishAsyncHandler else {
            fatalError("publishAsyncHandler must be set")
        }
        return try await publishAsyncHandler(data, topic, isRetained, qos)
    }

    func publish(_ someData: Data, to topicStr: String, isRetained: Bool, qos: MQTTQosLevel, result: ((Result<String, any Error>) -> Void)?) {
        guard let publishWithResultHandler else {
            fatalError("publishWithResultHandler must be set")
        }
        publishWithResultHandler(someData, topicStr, isRetained, qos, result)
    }

    func subscribe(to topicDict: [String: Int]) {
        guard let subscribeHandler else {
            fatalError("subscribeHandler must be set")
        }
        subscribeHandler(topicDict)
    }

    func subscribe(to topicDict: [String: Int], result: ((Result<Void, any Error>) -> Void)?) {
        guard let subscribeWithResultHandler else {
            fatalError("subscribeWithResultHandler must be set")
        }
        subscribeWithResultHandler(topicDict, result)
    }

    func subscribe<T>(to topics: [T]) where T: TopicStructurable {
        guard let subscribeTopicsHandler else {
            fatalError("subscribeTopicsHandler must be set")
        }
        subscribeTopicsHandler()
    }

    func subscribe<T>(to topics: [T], result: ((Result<Void, any Error>) -> Void)?) where T: TopicStructurable {
        guard let subscribeTopicsWithResultHandler else {
            fatalError("subscribeTopicsWithResultHandler must be set")
        }
        subscribeTopicsWithResultHandler(result)
    }

    func subscribeSingle(to topicDict: [String: Int]) {
        guard let subscribeSingleHandler else {
            fatalError("subscribeSingleHandler must be set")
        }
        subscribeSingleHandler(topicDict)
    }

    func subscribeSingle(to topicDict: [String: Int], result: ((Result<Void, any Error>) -> Void)?) {
        guard let subscribeSingleWithResultHandler else {
            fatalError("subscribeSingleWithResultHandler must be set")
        }
        subscribeSingleWithResultHandler(topicDict, result)
    }

    func unsubscribe(from topicsArr: [String]) {
        guard let unsubscribeHandler else {
            fatalError("unsubscribeHandler must be set")
        }
        unsubscribeHandler(topicsArr)
    }

    func unsubscribe(from topicsArr: [String], result: ((Result<Void, any Error>) -> Void)?) {
        guard let unsubscribeWithResultHandler else {
            fatalError("unsubscribeWithResultHandler must be set")
        }
        unsubscribeWithResultHandler(topicsArr, result)
    }

    func unsubscribe<T>(from topics: [T]) where T: TopicStructurable {
        guard let unsubscribeTopicsHandler else {
            fatalError("unsubscribeTopicsHandler must be set")
        }
        unsubscribeTopicsHandler()
    }

    func unsubscribe<T>(from topics: [T], result: ((Result<Void, any Error>) -> Void)?) where T: TopicStructurable {
        guard let unsubscribeTopicsWithResultHandler else {
            fatalError("unsubscribeTopicsWithResultHandler must be set")
        }
        unsubscribeTopicsWithResultHandler(result)
    }

    func restartMQTTService() {
        guard let restartMQTTServiceHandler else {
            fatalError("restartMQTTServiceHandler must be set")
        }
        restartMQTTServiceHandler()
    }
}

final class NullMQTTService: MQTTServiceProtocol {
    var subscriptions: [String: Int] {
        fatalError("Null Service Should Not Be Used")
    }

    var delegate: (any MQTTDelegate)? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var status: MQTTSessionStatus {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    func startSession() {
        fatalError("Null Service Should Not Be Used")
    }
    
    func connect() {
        fatalError("Null Service Should Not Be Used")
    }
    
    func connect(freshSession: Bool) {
        fatalError("Null Service Should Not Be Used")
    }
    
    func resubscribe() {
        fatalError("Null Service Should Not Be Used")
    }
    
    func executeOnConnection(closure: @escaping () -> Void) {
        fatalError("Null Service Should Not Be Used")
    }
    
    func disconnect() {
        fatalError("Null Service Should Not Be Used")
    }
    
    func disconnect(result: ((Result<Void, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }
    
    func reset() {
        fatalError("Null Service Should Not Be Used")
    }
    
    func publish(_ someData: Data, to topicStr: String, isRetained: Bool, qos: MQTTQosLevel) {
        fatalError("Null Service Should Not Be Used")
    }

    func publishAsync(_ data: Data, to topic: String, isRetained: Bool, qos: MQTTQosLevel) async throws -> String {
        fatalError("Null Service Should Not Be Used")
    }

    func publish(_ someData: Data, to topicStr: String, isRetained: Bool, qos: MQTTQosLevel, result: ((Result<String, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }
    
    func subscribe(to topicDict: [String: Int]) {
        fatalError("Null Service Should Not Be Used")
    }
    
    func subscribe(to topicDict: [String: Int], result: ((Result<Void, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }
    
    func subscribe<T>(to topics: [T]) where T: TopicStructurable {
        fatalError("Null Service Should Not Be Used")
    }
    
    func subscribe<T>(to topics: [T], result: ((Result<Void, any Error>) -> Void)?) where T: TopicStructurable {
        fatalError("Null Service Should Not Be Used")
    }
    
    func subscribeSingle(to topicDict: [String: Int]) {
        fatalError("Null Service Should Not Be Used")
    }
    
    func subscribeSingle(to topicDict: [String: Int], result: ((Result<Void, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }
    
    func unsubscribe(from topicsArr: [String]) {
        fatalError("Null Service Should Not Be Used")
    }
    
    func unsubscribe(from topicsArr: [String], result: ((Result<Void, any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }
    
    func unsubscribe<T>(from topics: [T]) where T: TopicStructurable {
        fatalError("Null Service Should Not Be Used")
    }
    
    func unsubscribe<T>(from topics: [T], result: ((Result<Void, any Error>) -> Void)?) where T: TopicStructurable {
        fatalError("Null Service Should Not Be Used")
    }
    
    func restartMQTTService() {
        fatalError("Null Service Should Not Be Used")
    }

    var subscriptionsPublisher: Published<[String: Int]>.Publisher {
        fatalError("Null Service Should Not Be Used")
    }

    var statusPublisher: Published<MQTTSessionStatus>.Publisher {
        fatalError("Null Service Should Not Be Used")
    }
}

final class MockDelegate: MQTTDelegate {
    var updateAnglesHandler: ((String, Double, Double) -> Void)?
    var updateDataPointHandler: ((String, String, String) -> Void)?
    var updateWearableBattWithValueHandler: ((String, String, String) -> Void)?

    func update(from baseStation: String, rollAngle: Double, pitchAngle: Double) {
        guard let updateAnglesHandler else {
            fatalError("updateAnglesHandler must be set")
        }
        updateAnglesHandler(baseStation, rollAngle, pitchAngle)
    }

    func updateDataPoint(topic: String, from baseStation: String, with: String) {
        guard let updateDataPointHandler else {
            fatalError("updateDataPointHandler must be set")
        }
        updateDataPointHandler(topic, baseStation, with)
    }

    func updateWearableBatteryLvl(from baseStation: String, wearableId: String, value: String) {
        guard let updateWearableBattWithValueHandler else {
            fatalError("updateWearableBattWithValueHandler must be set")
        }
        updateWearableBattWithValueHandler(baseStation, wearableId, value)
    }
}
