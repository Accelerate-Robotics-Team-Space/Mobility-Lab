//
//  SceneDelegate.swift
//  MobilityLab
//
//  Created by Anton Vishnyak on 4/3/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    @Injected(\.databaseManagementService) private var databaseManagementService
    @Injected(\.firebaseLogger) private var firebaseLogger
    @Injected(\.nodeManager) private var nodeManager
    @Injected(\.securityService) private var securityService
    @Injected(\.networkMonitor) private var networkMonitor
    @Injected(\.updateService) private var updateService
    private lazy var byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter
    }()

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Create the SwiftUI view that provides the window contents.
        databaseManagementService.start()
        nodeManager.start()
        securityService.start()
        networkMonitor.start()
        firebaseLogger.checkDidCrashDuringPreviousExecution()

        // Run update check after database service has been started
        // as it has a repository dependency
        updateService.checkDidUpdateFromLastLaunch()

        let contentView = PatientLandingView()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            hasANotch = window.safeAreaInsets.bottom > 0
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window

            window.makeKeyAndVisible()
        }
    }

    // MARK: Scene Life Cycles

    func sceneDidDisconnect(_ scene: UIScene) {
        logger.error("Scene did disconnect")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        logger.info("Scene will enter foreground")
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        let memory = Performance.memoryUsage()
        let totalMem = byteFormatter.string(fromByteCount: Int64(memory.total))
        let usedMem = byteFormatter.string(fromByteCount: Int64(memory.used))
        logger.warn("Scene did enter background. Memory Used: \(usedMem) (\(memory.used) B) of \(totalMem) Total")
    }
}
