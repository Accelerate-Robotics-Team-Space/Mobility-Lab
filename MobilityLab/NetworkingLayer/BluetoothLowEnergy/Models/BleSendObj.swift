//
//  BleSendObj.swift
//  MobilityLab
//
//  Created by Josh Franco on 8/25/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

struct BleSendObj {
    let characteristic: BleCharacteristic
    let sendData: Data
    
    /// This field is ONLY for BleCentral use, if this field is not nil then the central will attempt to send the data to the specified peripheral
    let specificPeripheralId: UUID?
}
