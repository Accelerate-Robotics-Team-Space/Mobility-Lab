//
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//
//  Modified from https://github.com/modesty/wearableD/blob/master/WearableD/BLEIDs.swift
//
//  Created by Zhang, Modesty on 1/9/15.
//  Copyright (c) 2015 Intuit. All rights reserved.

import CoreBluetooth
import Foundation

/// State machine for transmitting a BLE packet
enum BLESequence: UInt8 {
    case none, initialize, working, header, packet, error, end
}

struct BLEIDs {
    static func randomStringWithLength(len: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

        return String((0..<len).map { _ in letters.randomElement()! })
    }

    static func getCTTransId() -> String {
        return "wOS-\(BLEIDs.randomStringWithLength(len: 4))"
    }
}
