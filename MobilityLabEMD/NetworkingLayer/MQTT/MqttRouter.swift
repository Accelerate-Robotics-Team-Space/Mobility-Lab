//
//  MqttRouter.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 12/28/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

@globalActor public actor MQTTActor {
    public static let shared = MQTTActor()
}

final class MqttRouter<T: TopicStructurable> {
    private let routerQueue = DispatchQueue(label: "ALT_MQTT_Router", qos: .userInitiated)

    @MQTTActor
    private(set) var topics: Set<T> = []
    private var routerCompletion: (T.Publisher) -> Void = { _ in }
    private var isSubscribed = false
    
    private var publisherQueue: [T: T.Publisher] = [:]
    private var isPublishing = false
    
    private var logDict: [String: Int] = [:]
    private let logInterval: TimeInterval = 10
    private var shouldConnect = true
    var shouldReconnect = true

    private let notificationCenter: NotificationCenter
    private let networkMonitor: NetworkMonitor = .shared
    private let mqttService: MQTTServiceProtocol = MQTTService.shared

    @MQTTActor
    private var list: [String: Int] = [:]
    
    // MARK: - Computed Variables
    @MQTTActor private var topicsArr: [T] {
        return Array(topics)
    }
    
    private var isNetConnected: Bool {
        networkMonitor.isNetworkAvailable
    }
    
    // MARK: - Init
    init(for topics: T.Type, autoSubscribe: Bool = true) {
        self.notificationCenter = .default
        notificationCenter.addObserver(
            self,
            selector: #selector(connectionHandler),
            name: NetworkMonitor.connectionNote,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(disconnectionHandler),
            name: NetworkMonitor.disconnectionNote,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(noteHandler),
            name: MQTTService.subscriptionNote,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(statusHandler),
            name: MQTTService.statusNote,
            object: nil
        )

        logActivity()
    }

    deinit {
        Task { @MQTTActor [weak self] in
            self?.unsubscribe()
        }
		logger.info("💥💥 Router Deinit for \(String(describing: T.self)) 💥💥")
    }
    
    // MARK: - Util
    @MQTTActor
    func addNewTopic(_ topic: T) {
        topics.insert(topic)
        subscribe()
    }
    
    // MARK: - Publish
    @MQTTActor
    func publish(_ somePublisher: T.Publisher, to topic: T) {
        self.topics.insert(topic)
        self.publisherQueue[topic] = somePublisher
        self.startPublishing()
    }
    
    func startPublishing() {
        guard
            !isPublishing,
            let (topic, publication) = publisherQueue.first else { return }
        
        let syncResult: ((Result<String, Error>) -> Void) = { [weak self] syncResult in
            guard let self = self else { return }
            
            self.routerQueue.async {
                self.isPublishing.toggle()
                
                switch syncResult {
                case .success(let resultStr):
                    self.publisherQueue.removeValue(forKey: topic)
                    self.logDict[topic.simplifyStruct] = (self.logDict[topic.simplifyStruct] ?? 0) + 1
                    self.startPublishing()
                    
                    if NetworkingConstants.showMQTTLogs {
                        logger.info(resultStr)
                    }
                case .failure(let error):
                    logger.error("MQTT Publication Error: \(error.localizedDescription)")
                    self.startPublishing()
                }
            }
        }
        
        isPublishing.toggle()
        switch (isNetConnected, MQTTService.shared.status == .connected) {
        case (false, _):    // Is not connected to internet, attempt to sync via mesh
//            let transmitter = MultipeerTransmitter(topic: topic.structure,
//                                                   data: publication.toData(),
//                                                   isRetained: publication.isRetained,
//                                                   qosLvl: publication.qualityOfService)
//            syncViaMesh(transmitter, result: syncResult)
            // TODO: Implement syncViaMesh
            self.startPublishing()
        case (true, false): // Is connected but not connected to MQTT BE, attempt to connect to BE
            Task {
                self.mqttService.connect()
                self.isPublishing.toggle()
                self.startPublishing()
            }
        case (true, true):  // Is connected to both internet and MQTT BE, just publish the point
            mqttService.publish(
                publication.toData(),
                to: topic.structure,
                isRetained: publication.isRetained,
                qos: publication.qualityOfService.qosLvl, 
                result: syncResult
            )
        }
    }

    func reset() {
        shouldReconnect = false
        mqttService.reset()
    }

    func startSessionIfNeeded(completion: @escaping () -> Void) {
        if !shouldReconnect {
            if mqttService.status != .connected {
                mqttService.executeOnConnection {
                    completion()
                }
                mqttService.connect()
            } else {
                completion()
            }
        } else {
            completion()
        }
    }
    
    // MARK: - Private
//    private func syncViaMesh(_ transmitter: MultipeerTransmitter, result: @escaping (Result<String, Error>) -> Void) {
//        NodeManager.shared.trasnmit(transmitter) { transmitResult in
//            switch transmitResult {
//            case .success:
//                return result(.success("Transmitted via Mesh Network"))
//            case .failure(let error):
//                return result(.failure(error))
//            }
//        }
//    }
    
    // MARK: - Subscribe
    /// Subscribe to topics based on the TopicStructurable enum
    func subscribe() {
        guard !isSubscribed else { return }
        isSubscribed = true
    }

    @MQTTActor
    func subscribe(to topic: T) {
        self.topics.insert(topic)
        self.list[topic.structure] = topic.qualityOfService.rawValue
        subscribeIfNeededSingle(topicDict: [topic.structure: topic.qualityOfService.rawValue])
    }
    
    func subscribeIfNeededSingle(topicDict: [String: Int]) {
        switch (isNetConnected, mqttService.status == .connected) {
        case (false, _):    // Is not connected to internet, attempt to sync via mesh
//            let transmitter = MultipeerTransmitter(topic: topic.structure,
//                                                   data: publication.toData(),
//                                                   isRetained: publication.isRetained,
//                                                   qosLvl: publication.qualityOfService)
//            syncViaMesh(transmitter, result: syncResult)
            // TODO: Implement syncViaMesh
            self.subscribeIfNeededSingle(topicDict: topicDict)
        case (true, false): // Is connected but not connected to MQTT BE, attempt to connect to BE
            mqttService.connect()
        case (true, true):  // Is connected to both internet and MQTT BE, just subscribe
            mqttService.subscribeSingle(to: topicDict) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    if NetworkingConstants.showMQTTLogs {
                        logger.info("Subscribed")
                    }
                case .failure(let error):
                    logger.error(error.localizedDescription)
                    self.subscribeIfNeededSingle(topicDict: topicDict)
                }
            }
        }
    }
    
    /// Unsubscribe to topics based on the TopicStructurable enum
    @MQTTActor
    func unsubscribe() {
        guard isSubscribed else { return }
        isSubscribed = false
        mqttService.unsubscribe(from: topicsArr)
    }
    
    // MARK: - Objc Methods
    @objc @MQTTActor
    private func noteHandler(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let subscriptions = userInfo as? [String: Data] else {
            return
        }

        for topic in topics {
            guard
                let subData = subscriptions[topic.structure], !subData.isEmpty,
                let result = topic.decodeResult(subData) else { continue }
            routerCompletion(result)
        }
    }
    
    @objc
    private func connectionHandler() {
        routerQueue.async {
            self.startPublishing()
        }
        mqttService.resubscribe()
    }
    
    @objc
    private func disconnectionHandler() {
        // Disconnection logic here
        MQTTService.shared.status = .disconnected
    }
    
    @objc @MQTTActor
    private func statusHandler() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in // Delay with buffer time
            if self?.mqttService.status == .connected, self?.shouldConnect == true, self?.list.isEmpty == false {
                Task { @MQTTActor [weak self] in
                    let list = self?.list ?? [:]
                    list.forEach {
                        self?.subscribeIfNeededSingle(topicDict: [$0.key: $0.value])
                    }
                }
                self?.shouldConnect = false
            }
        }
    }
    
    // MARK: - Logging
    func logActivity() {
        routerQueue.asyncAfter(deadline: .now() + logInterval) {
            if !self.logDict.isEmpty {
                var logStr = "Published the following Topics: \n"
                for (key, value) in self.logDict {
                    logStr += "Topic: \(key) | Publish Count: \(value) \n"
                }
                
                logger.info(logStr)
                self.logDict.removeAll()
            }
            
            self.logActivity()
        }
    }
}
