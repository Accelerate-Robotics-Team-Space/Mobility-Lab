//
//  WatchConstants.swift
//  SensorSuite WatchKit Extension
//
//  Created by Josh Franco on 10/19/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation
import WatchKit

struct WatchConstants {
    static let foregroundNotification = WKApplication.didBecomeActiveNotification
    
    static var watchBatteryPercentage: Int {
        Int(roundf(WKInterfaceDevice.current().batteryLevel * 100))
    }
    
    static func enableBatteryMonitoring(_ isEnabled: Bool) {
        guard isEnabled != WKInterfaceDevice.current().isBatteryMonitoringEnabled else { return }
        
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = isEnabled
        logger.info("WKInterfaceDevice Battery Monitoring set to: \(isEnabled)")
    }
    
    static let versionNumStr = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    static let buildNumStr = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
}
