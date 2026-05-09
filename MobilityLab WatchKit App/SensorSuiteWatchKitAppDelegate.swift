//
//  MobilityLabWatchKitAppDelegate.swift
//
//  Created by Anton Vishnyak on 4/3/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import WatchKit

class MobilityLabWatchKitAppDelegate: NSObject, WKApplicationDelegate {

    private var runtimeSession: WKExtendedRuntimeSession?
    @Injected(\.sentryLogger) private var sentryLogger
    @Injected(\.watchConnectivityService) private var watchConnectivityService
    // TODO: Inject with FactoryKit when available
    private let deviceMotionManager: DeviceMotionManagerProtocol = DeviceMotionManager.shared
    @Injected(\.locationService) var locationService

    func applicationDidFinishLaunching() {
        sentryLogger.start()
        watchConnectivityService.activate()
    }

    func applicationDidBecomeActive() {
        logger.info("applicationDidBecomeActive \(runtimeSession?.expirationDate ?? Date())")
        startRuntimeSession()
        deviceMotionManager.sampleRate = 2.0
        locationService.requestAccess()
    }

    private func startRuntimeSession() {
        logger.info("Extended session start attempt")
        guard runtimeSession?.state != .running else { return }

        if runtimeSession == nil || runtimeSession?.state == .invalid {
            runtimeSession = WKExtendedRuntimeSession()
        }
        runtimeSession?.delegate = self
        runtimeSession?.start()
    }

    func applicationWillResignActive() {
        logger.info("applicationWillResignActive")
        deviceMotionManager.sampleRate = 1.0
    }
    
    func applicationWillEnterForeground() {
        logger.info("applicationWillEnterForeground")
    }

    func applicationDidEnterBackground() { 
        logger.info("applicationDidEnterBackground")
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks.
        // Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(
                    restoredDefaultState: true,
                    estimatedSnapshotExpiration: Date.distantFuture,
                    userInfo: nil
                )
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
        logger.info("handle background tasks\(backgroundTasks.map { "\($0): \(type(of: $0))" }.joined(separator: ", "))")
    }

    func handle(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        logger.info("Extended session handle(:) invoked")
        runtimeSession = extendedRuntimeSession
        runtimeSession?.delegate = self
    }
}

extension MobilityLabWatchKitAppDelegate: WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        logger.info("Extended session ended \(reason.rawValue), error: \(error?.localizedDescription ?? "")")
    }

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        logger.info("Extended session started")
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        logger.info("Extended session will expire")
        startRuntimeSession()
    }
}
