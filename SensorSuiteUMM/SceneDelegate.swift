//
//  SceneDelegate.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/12/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    @Injected(\.securityService) private var securityService
    @Injected(\.audioAlertHandler) private var audioAlertHandler
    @Injected(\.updateService) private var updateService
    var window: UIWindow?
    var resetTimer: Timer?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // Create the SwiftUI view that provides the window contents.
        setRootController(scene: scene)
        setupTimer()
        updateService.checkDidUpdateFromLastLaunch()
    }

    func resetRootController(scene: UIScene) {
        audioAlertHandler.stopSpeaking()
        resetServices()
        setRootController(scene: scene)
    }

    private func resetServices() {
        MQTTService.shared.disconnect()
    }

    private func setRootController(scene: UIScene) {
        DataStore.shared.setup()
        securityService.checkCertificateRevocationListIfNeeded()
        NetworkMonitor.shared.start()

        let contentView = DeviceRegisterLandingView()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)

            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window

            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily...
        // ...discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    private func setupTimer() {
        resetTimer?.invalidate()
        resetTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first,
                   let sceneDelegate: SceneDelegate = (scene.delegate as? SceneDelegate) {
                    sceneDelegate.resetRootController(scene: scene)
                }
            }
        }
    }
}

struct SceneDelegate_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, World!")
    }
}
