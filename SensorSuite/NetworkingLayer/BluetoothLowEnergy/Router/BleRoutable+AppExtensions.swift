//
//  BleRoutable+AppExtensions.swift
//  SensorSuite
//
//  Created by Josh Franco on 9/11/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth

extension BleRoutable {
    /// Constructs multiple CBMutableCharacteristics then creates a service with those characteristics
    /// - Returns: CBMutableService to be added to a peripheral manager
    func constructService(with chars: [CBCharacteristic]) -> CBMutableService {
        let newService = CBMutableService(type: self.service.uuid,
                                          primary: self.service.isPrimaryService)
        newService.characteristics = chars
        
        return newService
    }
}
