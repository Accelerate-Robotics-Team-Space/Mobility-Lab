//
//  MobilityLabWatchKitApp.swift
//  MobilityLab WatchKit App
//
//  Created by Vadym Riznychok on 2/28/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

@main
struct MobilityLabWatchKitApp: App {
    @WKApplicationDelegateAdaptor var appDelegate: MobilityLabWatchKitAppDelegate
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(DevSensorDriver())
                .environmentObject(LocalSensorDataBuffer())
        }
    }
}
