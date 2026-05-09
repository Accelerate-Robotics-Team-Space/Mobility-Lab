//
//  WatchConnectivityService.swift
//  MobilityLab WatchKit App
//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import HealthKit
import WatchConnectivity

protocol WatchConnectivityServiceProtocol: AnyObject {
    func activate()
    func sendHealthData(_ data: [String: Any])
}

extension Container {
    var watchConnectivityService: Factory<WatchConnectivityServiceProtocol> {
        self { WatchConnectivityService() }.cached
    }
}

final class WatchConnectivityService: NSObject, WatchConnectivityServiceProtocol {
    private var session: WCSession?
    private var pendingData: [String: Any]?

    override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else {
            logger.info("WatchConnectivity not supported on this device")
            return
        }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        logger.info("⌚️ WatchConnectivity session activating...")
    }

    func sendHealthData(_ data: [String: Any]) {
        guard let session, session.isReachable else {
            // Store for later transfer via application context
            pendingData = data
            sendViaApplicationContext(data)
            return
        }

        session.sendMessage(data, replyHandler: nil) { [weak self] error in
            logger.error("⌚️ Failed to send health data: \(error.localizedDescription)")
            self?.sendViaApplicationContext(data)
        }
    }

    private func sendViaApplicationContext(_ data: [String: Any]) {
        guard let session else { return }
        do {
            try session.updateApplicationContext(data)
        } catch {
            logger.error("⌚️ Failed to update application context: \(error.localizedDescription)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            logger.error("⌚️ WCSession activation failed: \(error.localizedDescription)")
        } else {
            logger.info("⌚️ WCSession activated with state: \(activationState.rawValue)")
            if let pending = pendingData {
                sendHealthData(pending)
                pendingData = nil
            }
        }
    }
}
