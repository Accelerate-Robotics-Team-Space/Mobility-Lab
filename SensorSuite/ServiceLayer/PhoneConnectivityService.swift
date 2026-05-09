//
//  PhoneConnectivityService.swift
//  SensorSuite
//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import WatchConnectivity

protocol PhoneConnectivityServiceProtocol: AnyObject {
    var healthDataPublisher: AnyPublisher<[String: Any], Never> { get }
    var isWatchReachable: Bool { get }
    func activate()
}

extension Container {
    var phoneConnectivityService: Factory<PhoneConnectivityServiceProtocol> {
        self { PhoneConnectivityService() }.cached
    }
}

final class PhoneConnectivityService: NSObject, PhoneConnectivityServiceProtocol {
    private let healthDataSubject = PassthroughSubject<[String: Any], Never>()
    private var session: WCSession?

    var healthDataPublisher: AnyPublisher<[String: Any], Never> {
        healthDataSubject.eraseToAnyPublisher()
    }

    var isWatchReachable: Bool {
        session?.isReachable ?? false
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            logger.error("WCSession activation failed: \(error.localizedDescription)")
        } else {
            logger.info("WCSession activated: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        logger.info("WCSession deactivated, reactivating...")
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.healthDataSubject.send(message)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.healthDataSubject.send(applicationContext)
        }
    }
}
