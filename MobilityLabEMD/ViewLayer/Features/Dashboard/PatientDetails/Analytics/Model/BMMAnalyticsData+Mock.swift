//
//  BMMAnalyticsData+Mock.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 10/23/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import Foundation

extension BMMAnalyticsData {
    static func mockData() -> BMMAnalyticsData { // swiftlint:disable:this function_body_length
        func posFrom(ind: Int) -> PositionalFlagCategory {
            switch ind {
            case 0:
                return .left
            case 1:
                return .supine
            default:
                return .right
            }
        }
        var ind = 0
        var logs: [ActivityStartEnd] = []
        var timestamps: [TurnTimestamp] = []
        
        for hour in [Int](0...11) {
            let intAppend = TimeInterval((2 * hour * .secondsPerHour) + (60 + 60 * (ind % 2)))
            var startTime = intAppend
            var endTime = startTime + TimeInterval(2 * 60 * 60)
            if hour == 5 || hour == 9 {
                endTime -= .secondsPerHour
                let log = ActivityStartEnd(
                    startDate: Date().startOfDay.addingTimeInterval(startTime),
                    endDate: Date().startOfDay.addingTimeInterval(endTime),
                    actualPosition: hour == 5 ? posFrom(ind: 1) : posFrom(ind: ind),
                    targetPosition: posFrom(ind: ind),
                    startTime: startTime,
                    endTime: endTime,
                    isPause: false
                )
                logs.append(log)
                if hour != 5 {
                    timestamps.append(TurnTimestamp(turnTime: log.startDate, targetPosition: log.targetPosition))
                }
                startTime = endTime
                endTime += .secondsPerHour
            }

            if hour == 7 {
                endTime -= 1.5 * .secondsPerHour
                let log = ActivityStartEnd(
                    startDate: Date().startOfDay.addingTimeInterval(startTime),
                    endDate: Date().startOfDay.addingTimeInterval(endTime),
                    actualPosition: hour == 7 ? .other : posFrom(ind: ind),
                    targetPosition: posFrom(ind: ind),
                    startTime: startTime,
                    endTime: endTime,
                    isPause: false
                )
                logs.append(log)
                startTime = endTime
                endTime += 1.5 * .secondsPerHour
            }

            if hour == 3 {
                endTime -= 1.5 * .secondsPerHour
                let log = ActivityStartEnd(
                    startDate: Date().startOfDay.addingTimeInterval(startTime),
                    endDate: Date().startOfDay.addingTimeInterval(endTime),
                    actualPosition: hour == 3 ? .partialLeft : posFrom(ind: ind),
                    targetPosition: posFrom(ind: ind),
                    startTime: startTime,
                    endTime: endTime,
                    isPause: false
                )
                logs.append(log)
                timestamps.append(TurnTimestamp(turnTime: log.startDate, targetPosition: log.targetPosition))
                startTime = endTime
                endTime += .secondsPerHour
            }

            if hour == 8 {
                endTime -= .secondsPerHour
                let log = ActivityStartEnd(
                    startDate: Date().startOfDay.addingTimeInterval(startTime),
                    endDate: Date().startOfDay.addingTimeInterval(endTime),
                    actualPosition: hour == 8 ? .partialRight : posFrom(ind: ind),
                    targetPosition: posFrom(ind: ind),
                    startTime: startTime,
                    endTime: endTime,
                    isPause: false
                )
                logs.append(log)
                timestamps.append(TurnTimestamp(turnTime: log.startDate, targetPosition: log.targetPosition))
                startTime = endTime
                endTime += .secondsPerHour
            }

            let log = ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(startTime),
                endDate: Date().startOfDay.addingTimeInterval(endTime),
                actualPosition: posFrom(ind: ind),
                targetPosition: posFrom(ind: ind),
                startTime: startTime,
                endTime: endTime,
                isPause: hour == 9
            )
            logs.append(log)
            if hour != 9 && hour != 3 && hour != 8 {
                timestamps.append(TurnTimestamp(turnTime: log.startDate, targetPosition: log.targetPosition))
            }
            if ind == 2 {
                ind = 0
            } else {
                ind += 1
            }
        }

        return BMMAnalyticsData(logs: logs, timestamps: timestamps)
    }
}
