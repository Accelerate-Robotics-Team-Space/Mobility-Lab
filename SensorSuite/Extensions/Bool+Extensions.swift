//
//  Bool+Extensions.swift
//  SensorSuite
//
//  Created by Josh Franco on 8/31/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Bool: Serializable {
    private static var falseByte = [0x00]
    private static var trueByte = [0x01]
    
    init?(serialize data: Data) {
        switch data {
        case Data(bytes: Bool.falseByte, count: Bool.falseByte.count):
            self = false
        case Data(bytes: Bool.trueByte, count: Bool.trueByte.count):
            self = true
        default:
            return nil
        }
    }
    
    func toData() -> Data {
        if self == true {
            return Data(bytes: Bool.trueByte,
                        count: Bool.trueByte.count)
        } else {
            return Data(bytes: Bool.falseByte,
                        count: Bool.falseByte.count)
        }
    }
}
