//
//  BleCharacteristic+Extension.swift
//  MobilityLab
//
//  Created by Josh Franco on 8/25/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import Foundation

// This extension is for MobilityLab methods ONLY
extension BleCharacteristic {
    /// Makes a CBMutableCharacteristic from the BleCharacteristic
    var constructChar: CBMutableCharacteristic {
        switch self {
        default:
            return CBMutableCharacteristic(type: self.uuid,
                                           properties: [.notify, .writeWithoutResponse],
                                           value: nil,
                                           permissions: [.readable, .writeable])
        }
    }
}
