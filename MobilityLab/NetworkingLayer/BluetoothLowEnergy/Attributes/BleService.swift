//
//  BleService.swift
//  MobilityLab
//
//  Created by Josh Franco on 8/25/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import Foundation

enum BleService: String {
    case watchProvisioning = "DB3876A6-639A-4632-A579-A34A7DFEF840"
    case dataFeed = "15C3D6E3-04A8-4DA9-8F33-C6CDEBA4DEE1"
    
    var uuid: CBUUID {
        CBUUID(string: self.rawValue)
    }
    
    var isPrimaryService: Bool {
        true
    }
}
