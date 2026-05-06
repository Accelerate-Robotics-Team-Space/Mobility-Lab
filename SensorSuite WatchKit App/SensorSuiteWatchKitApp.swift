//
//  SensorSuiteWatchKitApp.swift
//  SensorSuite WatchKit App
//
//  Created by Vadym Riznychok on 2/28/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

@main
struct SensorSuiteWatchKitApp: App {
    @WKApplicationDelegateAdaptor var appDelegate: SensorSuiteWatchKitAppDelegate
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(DevSensorDriver())
                .environmentObject(LocalSensorDataBuffer())
        }
    }
}
