//
//  HomeDriver.swift
//  SensorSuite WatchKit Extension
//
//  Created by Josh Franco on 10/28/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import WatchKit

class HomeDriver: NSObject, ObservableObject {
    @Published var scanDriver: ScanDriver

    var connectionDriver = BLEConnectionDriver(router: BleDataFeedRouter.std)
    
    // MARK: - Init
    override init() {
        WatchConstants.enableBatteryMonitoring(true)
        scanDriver = ScanDriver(connectionDriver: connectionDriver)
        super.init()
    }
    
    // MARK: - Util
    func getBuildInfoStr() -> String {
        if ALTEnvironment.current != .prod {
            let versionNum = R.string.localizable.versionNum(WatchConstants.versionNumStr)
            let env = ALTEnvironment.current.abbreviation
            
            return "\(versionNum) \(WatchConstants.buildNumStr) | \(env)"
        } else {
            let versionNum = R.string.localizable.versionNum(WatchConstants.versionNumStr)
            
            return "\(versionNum)"
        }
    }
}
