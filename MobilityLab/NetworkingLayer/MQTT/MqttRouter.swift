//
//  MqttRouter.swift
//  MobilityLab
//
//  Created by Josh Franco on 9/9/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation

final class MqttRouter<T: TopicStructurable>: ObservableObject {
    private let routerQueue = DispatchQueue(label: "ALT_MQTT_Router",
                                            qos: .userInitiated)
    
    private(set) var topics: Set<T>
    private var routerCompletion: (T.Publisher) -> Void = { _ in }
    private var isSubscribed = false
    
    private var publisherQueue: [T: T.Publisher] = [:]
	private var publishingTimer: DispatchSourceTimer?
	private var isPublishing = false
    
    private var logDict: [String: Int] = [:]
    private let logInterval: TimeInterval = 30

    // MARK: - Computed Variables
    private var topicsArr: [T] {
        Array(topics)
    }

    // MARK: Services
    private let container: Container
    private let networkMonitor: NetworkMonitorProtocol
    private let notificationCenter: NotificationCenterServiceProtocol
    private let mqttService: MQTTServiceProtocol
    private let nodeManager: NodeManagerProtocol

    private var isNetConnected: Bool {
        networkMonitor.isConnected
    }
    
    // MARK: - Init
    init(for topics: T.Type, autoSubscribe: Bool = true, container: Container = .shared) {
        self.container = container
        self.networkMonitor = container.networkMonitor.resolve()
        self.notificationCenter = container.notificationCenter.resolve()
        self.mqttService = container.mqttService.resolve()
        self.nodeManager = container.nodeManager.resolve()

        self.topics = []
        
        notificationCenter.addObserver(self, selector: #selector(connectionHandler), name: NetworkMonitor.connectionNote, object: nil)
        notificationCenter.addObserver(self, selector: #selector(disconnectionHandler), name: NetworkMonitor.disconnectionNote, object: nil)
        notificationCenter.addObserver(self, selector: #selector(noteHandler), name: MQTTService.subscriptionNote, object: nil)

        if autoSubscribe {
            subscribe()
        }
        
        logActivity()
    }
    
    deinit {
        unsubscribe()
		logger.debug("💥💥 Router Deinit for \(String(describing: T.self)) 💥💥")
    }
    
    // MARK: - Util
    func addNewTopic(_ topic: T) {
        topics.insert(topic)
        subscribe()
    }
    
    // MARK: - Publish
    func publish(_ somePublisher: T.Publisher, to topic: T) {
        routerQueue.async { [weak self] in
            guard let self = self else { return }
            self.topics.insert(topic)
            self.publisherQueue[topic] = somePublisher
            self.startPublishing()
        }
    }
    
    func startPublishing() {
        self.routerQueue.async { [weak self] in
            guard let self = self else { return }
            guard
                !isPublishing,
                let (topic, publication) = publisherQueue.first else { return }

            let syncResult: ((Result<String, Error>) -> Void) = { [weak self] syncResult in
                guard let self = self else { return }
                self.routerQueue.async { [weak self] in
                    guard let self = self else { return }
                    stopTimer()
                    self.isPublishing = false

                    switch syncResult {
                    case .success(let resultStr):
                        self.publisherQueue.removeValue(forKey: topic)
                        self.logDict[topic.simplifyStruct] = (self.logDict[topic.simplifyStruct] ?? 0) + 1
                        self.startPublishing()

                        if NetworkingConstants.showMQTTLogs {
                            logger.debug(resultStr)
                        }
                    case .failure(let error):
                        logger.error("MQTT Publication Error: \(error.localizedDescription)")
                    }
                }
            }

            self.isPublishing = true
            switch (self.isNetConnected, mqttService.status == .connected) {
            case (false, _):    // Is not connected to internet, attempt to sync via mesh
                self.isPublishing = false
            case (true, false): // Is connected but not connected to MQTT BE, attempt to connect to BE
                self.isPublishing = false
                mqttService.executeOnConnection { [weak self] in
                    self?.startPublishing()
                }
            case (true, true):  // Is connected to both internet and MQTT BE, just publish the point
                self.startTimer()
                mqttService.publish(
                    publication.toData(),
                    to: topic.structure,
                    isRetained: publication.isRetained,
                    qos: publication.qualityOfService,
                    result: syncResult
                )
            }
        }
    }

	func startTimer() {
		stopTimer()
        let timer = DispatchSource.makeTimerSource(queue: self.routerQueue)
        self.publishingTimer = timer
        timer.schedule(deadline: .now() + 10) // single-shot after 10s
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            // mutate only on routerQueue
            self.isPublishing = false
            self.stopTimer()
        }
        timer.resume()
	}
	
    func stopTimer() {
            // stay on routerQueue
            if let timer = publishingTimer {
                timer.cancel()
                publishingTimer = nil
            }
        }

    // MARK: - Private
    private func syncViaMesh(_ transmitter: MultipeerTransmitter, result: @escaping (Result<String, Error>) -> Void) {
        nodeManager.transmit(transmitter) { transmitResult in
            switch transmitResult {
            case .success:
                return result(.success("Transmitted via Mesh Network"))
            case .failure(let error):
                logger.error(error.localizedDescription)
                return result(.failure(error))
            }
        }
    }
    
    // MARK: - Subscribe
    /// Subscribe to topics based on the TopicStructurable enum
    func subscribe() {
        routerQueue.async { [weak self] in
            guard let self else { return }

            guard !isSubscribed else { return }
            isSubscribed = true

            subscribeIfNeeded()
        }
    }
    
    func subscribeIfNeeded() {
        logger.info("subscribeIfNeeded called")
        let topicsToSubscribe = topicsArr.filter { mqttService.subscriptions[$0.structure] == nil }
        mqttService.subscribe(to: topicsToSubscribe)
    }
    
    /// Unsubscribe to topics based on the TopicStructurable enum
    func unsubscribe() {
        routerQueue.async { [weak self] in
            guard let self else { return }
            guard isSubscribed else { return }
            isSubscribed = false

            mqttService.unsubscribe(from: topicsArr)
        }
    }
    
    // MARK: - Objc Methods
    @objc
    private func noteHandler(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let subscriptions = userInfo as? [String: Data] else {
            return
        }
        
        for topic in topics {
            guard let subData = subscriptions[topic.structure],
                  !subData.isEmpty,
                  let result = topic.decodeResult(subData) else {
                continue
            }
            routerCompletion(result)
        }
    }
    
    @objc
    private func connectionHandler() {
        routerQueue.async { [weak self] in
            guard let self = self else { return }
            self.resetIsPublishing()
            self.startPublishing()
        }
    }
    
    @objc
    private func disconnectionHandler() {
        // Disconnection logic here
    }
    
    // MARK: - Logging
    func logActivity() {
        routerQueue.asyncAfter(deadline: .now() + logInterval) { [weak self] in
            guard let self else { return }
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

    func resetIsPublishing() {
        isPublishing = false
    }
}
