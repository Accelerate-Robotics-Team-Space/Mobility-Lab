//
//  AppDelegate.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/12/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import AVFAudio
import FactoryKit
import FirebaseCore
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    @Injected(\.sentryLogger) private var sentryLogger

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        sentryLogger.start()

        //        let audioSession = AVAudioSession.sharedInstance()
        //        do {
        //            try audioSession.setCategory(AVAudioSession.Category.playback)
        //            try audioSession.setActive(true)
        //        } catch {
        //            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        //        }

        FirebaseApp.configure()
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication,
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
