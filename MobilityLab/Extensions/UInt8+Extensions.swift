//
//  UInt8+Extensions.swift
//  MobilityLab
//
//  Created by Josh Franco on 12/2/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

extension UInt8: Serializable {
    init?(serialize data: Data) {
        var number: UInt8 = 0
        data.copyBytes(to: &number, count: MemoryLayout<UInt8>.size)
        self = number
    }
    
    func toData() -> Data {
        var tempSelf = self
        return Data(bytes: &tempSelf, count: MemoryLayout<UInt8>.size)
    }
}
