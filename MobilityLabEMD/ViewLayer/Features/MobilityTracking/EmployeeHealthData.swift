//
//  EmployeeHealthData.swift
//  MobilityLabEMD
//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

struct EmployeeHealthData: Identifiable {
    let id: String
    let name: String
    let department: String
    var steps: Double = 0
    var distance: Double = 0        // meters
    var heartRate: Double = 0       // bpm
    var spO2: Double = 0            // percentage (0-100)
    var calories: Double = 0        // kcal
    var activeMinutes: Double = 0
    var isConnected: Bool = false
    var lastUpdated: Date = Date()

    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    var formattedSteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: steps)) ?? "0"
    }

    var formattedDistance: String {
        String(format: "%.1f", distance / 1000.0)
    }

    var formattedHeartRate: String {
        heartRate > 0 ? String(format: "%.0f", heartRate) : "--"
    }

    var formattedSpO2: String {
        spO2 > 0 ? String(format: "%.0f", spO2) : "--"
    }

    var formattedCalories: String {
        String(format: "%.0f", calories)
    }

    var formattedActiveMinutes: String {
        String(format: "%.0f", activeMinutes)
    }
}
