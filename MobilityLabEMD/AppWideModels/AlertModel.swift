//
//  AlertModel.swift
//  MobilityLab EMD
//
//  Created by Nguyen Bui on 6/8/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import Foundation

struct AlertModel {
    var type: AlertType
    var unit: String
    var roomBed: String
    
    enum AlertType: String {
        case turnSoon = "turn-soon"
        case overdue = "overdue"
        case nonTargetPosition = "non-target-position"
        case bmmLowBattery = "bmm-low-battery"
        case sensorLowBattery = "sensor-low-battery"
        
        var message: String {
            switch self {
            case .turnSoon:
                return ". It's time to turn your patient"
            case .overdue:
                return ". It's time to turn your patient"
            case .nonTargetPosition:
                return ""
            case .sensorLowBattery:
                return ""
            case .bmmLowBattery:
                return ""
            }
        }
    }
    
    var textToSpeech: String {
        switch type {
        case .turnSoon:
            "BMM from \(unit), room \(roomBed) has less than 10 minutes left. \(type.message)."
        case .overdue:
            "BMM from \(unit), room \(roomBed) is \(type.rawValue). \(type.message)."
        case .nonTargetPosition:
            "BMM from \(unit), room \(roomBed) is in a non-target position."
        case .sensorLowBattery:
            "Sensor from \(unit), room \(roomBed) is low on battery."
        case .bmmLowBattery:
            "BMM from \(unit), room \(roomBed) is low on battery."
        }
    }
}
