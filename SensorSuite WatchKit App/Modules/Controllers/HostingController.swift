//
//  HostingController.swift
//  SensorSuite WatchKit Extension
//
//  Created by Anton Vishnyak on 4/3/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation
import SwiftUI
import WatchKit

@available(watchOSApplicationExtension 8.0, *)
class HostingController: WKHostingController<AnyView> {
    override var body: AnyView {
        let host = HomeView()
            .environmentObject(DevSensorDriver())
            .environmentObject(LocalSensorDataBuffer())
        
        return AnyView(host)
    }
}
