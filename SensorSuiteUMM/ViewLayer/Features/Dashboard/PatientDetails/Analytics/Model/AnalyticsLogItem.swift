//
//  AnalyticsLogItem.swift
//  SensorSuite UMM
//
//  Created by Vadym Riznychok on 6/16/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import Foundation

struct AnalyticsLogItem: Serializable {
    let bmmMonitoringState: String?
    let bmmPauseReason: String?
    let isWrongPosition: Bool
    let actualPosition: String
    let actualPositionStarted: Date
    let actualPositionEnded: Date
    let startingTargetPosition: String
    let startingTimeRemaining: Double
    let bmmName: String
    let bmmId: String
    let sessionId: String
    let patientId: String

    func toActivity() -> ActivityStartEnd {
        let selectedMidnight = Calendar.current.startOfDay(for: actualPositionStarted)

        let startTime = actualPositionStarted.timeIntervalSince(selectedMidnight)
        let endTime = actualPositionEnded.timeIntervalSince(selectedMidnight)

        return ActivityStartEnd(
            startDate: actualPositionStarted,
            endDate: actualPositionEnded,
            actualPosition: PositionalFlagCategory(actualPosition),
            targetPosition: PositionalFlagCategory(startingTargetPosition),
            startTime: startTime,
            endTime: endTime,
            isPause: bmmMonitoringState == "onPause"
        )
    }
}

extension AnalyticsLogItem: Codable { }
extension AnalyticsLogItem: Equatable { }
