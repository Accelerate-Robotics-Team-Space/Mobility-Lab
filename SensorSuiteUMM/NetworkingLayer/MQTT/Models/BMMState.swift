//
//  BMMState.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/24/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

enum BMMState: Int {
    case connected = 0
    case disconnected = 1
    case lowBattery = 2

    func toString() -> String {
        switch self {
        case.connected:
            return "connected"
        case .disconnected:
            return "disconnected"
        case .lowBattery:
            return "low battery"
        }
    }
}

enum SensorState: Int {
    case connected = 0
    case disconnected = 1
    case lowBattery = 2

    func toString() -> String {
        switch self {
        case.connected:
            return "connected"
        case .disconnected:
            return "disconnected"
        case .lowBattery:
            return "low battery"
        }
    }
}

enum PatientState: Int {
    case nonTargetPosition
    case overdue
    case turnSoon
    case swappingSensor
    case swappingPatch
    case paused
    case active
    case ready
    case noSession
    case unassigned

    func toString() -> String {
        switch self {
        case .active:
            return "monitoring"
        case .paused:
            return "paused"
        case .turnSoon:
            return "turn soon"
        case .overdue:
            return "overdue"
        case .swappingSensor, .swappingPatch:
            return "swapping"
        case .nonTargetPosition:
            return "non-target"
        case .ready:
            return "ready"
        case .noSession:
            return "no session"
        case .unassigned:
            return "unassigned"
        }
    }

    init?(pauseString: String) {
        switch pauseString {
        case "Swapping Sensor":
            self = .swappingSensor
        case "Swapping Patch", "Replacing Patch":
            self = .swappingPatch
        case "End Session":
            self = .unassigned
        default:
            self = .paused
        }
    }

    var isMonitoring: Bool {
        return [.active, .overdue, .turnSoon, .nonTargetPosition].contains(self)
    }
}
