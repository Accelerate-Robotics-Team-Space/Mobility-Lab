//
//  BMMCardData.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 3/20/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

struct BMMCardData: Equatable {
    var patientState: PatientState?
    var bmmState: BMMState
    var sensorState: SensorState
    var targetPos: PositionalFlagCategory?
    var currentPos: PositionalFlagCategory?
    var positionsToAvoid: [PositionalFlagCategory]
    var lastSeen: BMMLastSeen?

    var roomBed: String?

    var disconnectedTime: TimeInterval = 0
    var timeRemaining: TimeInterval = 0
    var swappingTime: TimeInterval = 0
    var pausedTime: TimeInterval = 0

    var rollAngle: Double = 0.0
    var pitchAngle: Double = 0.0

    var bmmBatteryPercentage: Int?
    var sensorBatteryPercentage: Int?

    var currentAlert: AlertLevel

    var isAlive = false
    var isStatic = false
    var isOverdue = false

    // MARK: - Computed properties
    var nextPos: PositionalFlagCategory {
        if targetPos == .left {
            return positionsToAvoid.contains(.supine) ? .right : .supine
        } else if targetPos == .supine {
            return positionsToAvoid.contains(.right) ? .left : .right
        } else if targetPos == .right {
            return positionsToAvoid.contains(.left) ? .supine : .left
        } else {
            return .supine // default next position for default target position "left"
        }
    }
    var swappingType: String {
        if patientState == .swappingSensor {
            return "Swapping Sensor"
        } else if patientState == .swappingPatch {
            return "Replacing Patch"
        } else {
            return ""
        }
    }
    var swappingTimeStr: String {
        displayString(from: swappingTime)
    }
    var timeRemainingStr: String {
        displayString(from: timeRemaining)
    }
    var disconnectedTimeStr: String {
        displayString(from: disconnectedTime)
    }
    var pausedTimeStr: String {
        "+" + displayHoursMinutesString(from: pausedTime)
    }
    var positionalTimeRemainingStr: String {
        DateComponentsFormatter.positionalBriefTime
            .string(from: timeRemaining)?
            .replacingOccurrences(of: "-", with: "") ?? "Time Format Error"
    }
    var canShowPatientDetails: Bool { patientState != .unassigned && patientState != .noSession }
    var canShowCompliance: Bool {
        !(!canShowPatientDetails
            || patientState == .swappingPatch
            || patientState == .swappingSensor
            || bmmState == .disconnected
            || sensorState == .disconnected
            || patientState == .unassigned
            || patientState == .noSession)
    }
    var canShowLowBatteryWarningBanner: Bool {
        guard let patientState = patientState else { return false }
        switch patientState {
        case .active, .paused, .turnSoon:
            return true
        case .swappingSensor, .swappingPatch, .nonTargetPosition, .ready, .noSession, .unassigned, .overdue:
            return false
        }
    }
    var isLowBatteryCritical: Bool {
        if let bmmBattery = bmmBatteryPercentage, bmmBattery <= 10 {
            return true
        } else if let sensorBattery = sensorBatteryPercentage, sensorBattery <= 10 {
            return true
        }
        return false
    }
    var isLowBatteryWarning: Bool {
        if let bmmBattery = bmmBatteryPercentage, bmmBattery > 10 && bmmBattery <= 20 {
            return true
        } else if let sensorBattery = sensorBatteryPercentage,
                      sensorBattery > 10 && sensorBattery <= 20 {
            return true
        }
        return false
    }

    var shouldGrayOut: Bool {
        patientState == .paused &&
        bmmState != .disconnected &&
        sensorState != .disconnected
    }
    var isDisconnected: Bool {
        patientState == .swappingPatch ||
        patientState == .swappingSensor ||
        sensorState == .disconnected ||
        bmmState == .disconnected
    }
}

private extension BMMCardData {
    func displayString(from timeInterval: TimeInterval) -> String {
        return DateComponentsFormatter.briefTime
            .string(from: timeInterval)?
            .replacingOccurrences(of: "-", with: "") ?? "Time Format Error"
    }

    func displayMinutesString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(max(0, floor(timeInterval / 60)))
        return "\(minutes) min"
    }

    func displayHoursMinutesString(from timeInterval: TimeInterval) -> String {
        let totalMinutes = Int(max(0, floor(timeInterval / 60)))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        switch (hours, minutes) {
        case (0, let min):
            return "\(min) mins"
        case (let hour, 0):
            return "\(hour) hr"
        default:
            return "\(hours) hr \(minutes) mins"
        }
    }
}
