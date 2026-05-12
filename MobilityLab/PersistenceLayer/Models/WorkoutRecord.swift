//
//  WorkoutRecord.swift
//  MobilityLab
//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB
import SwiftUI

struct WorkoutRecord: DataStorable, Hashable {
    private(set) var id: Int64?
    let startTime: Date
    private(set) var endTime: Date
    private(set) var steps: Double
    private(set) var distance: Double          // meters
    private(set) var heartRateAvg: Double
    private(set) var heartRateMax: Double
    private(set) var calories: Double
    private(set) var spO2: Double
    private(set) var wearLocation: String      // wrist, chest, ankle
    private(set) var isSynced: Bool
    private(set) var healthKitWorkoutId: String?

    // MARK: - Init

    init(
        startTime: Date,
        endTime: Date,
        steps: Double = 0,
        distance: Double = 0,
        heartRateAvg: Double = 0,
        heartRateMax: Double = 0,
        calories: Double = 0,
        spO2: Double = 0,
        wearLocation: String = "wrist",
        healthKitWorkoutId: String? = nil
    ) {
        self.id = nil
        self.startTime = startTime
        self.endTime = endTime
        self.steps = steps
        self.distance = distance
        self.heartRateAvg = heartRateAvg
        self.heartRateMax = heartRateMax
        self.calories = calories
        self.spO2 = spO2
        self.wearLocation = wearLocation
        self.isSynced = false
        self.healthKitWorkoutId = healthKitWorkoutId
    }

    // MARK: - MutablePersistableRecord

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    mutating func updateSynced(_ synced: Bool) {
        isSynced = synced
    }
}

// MARK: - Conversion

extension WorkoutRecord {
    func toActivityRecord() -> ActivityRecord {
        ActivityRecord(
            title: "Activity",
            icon: "figure.walk",
            color: .indigo1,
            startTime: startTime,
            endTime: endTime,
            steps: steps,
            distance: distance,
            heartRateAvg: heartRateAvg,
            heartRateMax: heartRateMax,
            calories: calories,
            spO2: spO2
        )
    }
}

// MARK: - Codable

extension WorkoutRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case startTime
        case endTime
        case steps
        case distance
        case heartRateAvg
        case heartRateMax
        case calories
        case spO2
        case wearLocation
        case isSynced
        case healthKitWorkoutId
    }
}
