//
//  AnalyticsResponse.swift
//  SensorSuite BMM
//
//  Created by Vadym Riznychok on 6/16/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import Foundation

struct AnalyticsResponse: Serializable {
    let bmmPositions: [String: [AnalyticsLogItem]]
    let turnsListDetail: [String: [TurnTimestamp]]

    func toAnalyticsData(forDate: Date) -> BMMAnalyticsData {
        var activities: [ActivityStartEnd] = []
        var timestamps: [TurnTimestamp] = []

        bmmPositions.values.first?
            .forEach({ item in
                guard item.bmmMonitoringState != "onStart" else {
                    return
                }
                var activity = item.toActivity()

                let spillOver = activity.startDate.startOfDay < forDate.startOfDay || activity.endDate.startOfDay > forDate.startOfDay
                
                if spillOver {
                    if activity.startDate < forDate.startOfDay {
                        activity.startTime = 0
                        if activity.endDate < forDate.endOfDay {
                            activity.endTime = activity.endDate.timeIntervalSince(activity.endDate.startOfDay)
                        }
                    }
                    if activity.endDate > forDate.endOfDay {
                        activity.endTime = TimeInterval.secondsPerDay // 86400.0
                    }
                }
                
                activities.append(activity)
            })
        timestamps = turnsListDetail.flatMap { $0.value }

        return BMMAnalyticsData(logs: activities, timestamps: timestamps)
    }
}

extension AnalyticsResponse: Codable { }
extension AnalyticsResponse: Equatable { }
