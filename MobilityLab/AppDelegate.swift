//
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import AVFAudio
import FactoryKit
import UIKit

var hasANotch = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    @Injected(\.firebaseLogger) private var firebaseLogger
    @Injected(\.sentryLogger) private var sentryLogger
    private lazy var byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter
    }()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        sentryLogger.start()
        firebaseLogger.start()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setActive(true)
        } catch {
            logger.error("Setting category to AVAudioSessionCategoryPlayback failed. Error: \(error.localizedDescription)")
        }

        return true
    }

    // MARK: Application Life Cycles

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        let memory = Performance.memoryUsage()
        let totalMem = byteFormatter.string(fromByteCount: Int64(memory.total))
        let usedMem = byteFormatter.string(fromByteCount: Int64(memory.used))
        logger.warn("App received memory warning. Memory Used: \(usedMem) (\(memory.used) B) of \(totalMem) Total")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        logger.error("App will terminate")
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after
        // application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
