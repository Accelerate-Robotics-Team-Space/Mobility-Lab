//
//  ALTActivityLog+Mock.swift
//  SensorSuite BMM
//
//  Created by Vadym Riznychok on 4/30/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Date {
    var startOfDay: Date {
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self) ?? Date()
    }

    var endOfDay: Date {
        return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? Date()
    }
}

extension ALTActivityLog {
    static func mockData() -> [ALTActivityLog] {
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
        var logs: [ALTActivityLog] = []
        for hour in [Int](0...11) {
            let intAppend = TimeInterval((2 * hour * .secondsPerHour) + (60 + 60 * (ind % 2)))
            var startTime = intAppend
            var endTime = startTime + TimeInterval(2 * .secondsPerHour)
            if hour == 5 || hour == 9 {
                endTime -= 60 * 60
                let log = ALTActivityLog(session: ALTSession.dev,
                                         actualPositionStarted: Date().startOfDay.addingTimeInterval(startTime),
                                         actualPositionEnded: Date().startOfDay.addingTimeInterval(endTime),
                                         actualPosition: hour == 5 ? posFrom(ind: 1) : posFrom(ind: ind),
                                         startingTarget: posFrom(ind: ind),
                                         startingTimeRemaining: 0.0,
                                         bmmMonitoringState: PatientMonitorState.onResume.rawValue,
                                         bmmPauseReason: "",
                                         isWrongPosition: hour == 5,
                                         hospitalRoomBedId: "",
                                         mqttTopicStr: "",
                                         updateId: "",
                                         headOfBedAngle: 15,
                                         turnAngle: 10,
                                         endingTargetPosition: "",
                                         mock: true)
                logs.append(log)

                startTime = endTime
                endTime += .secondsPerHour
            }

            if hour == 7 {
                endTime -= 1.5 * .secondsPerHour
                let log = ALTActivityLog(session: ALTSession.dev,
                                         actualPositionStarted: Date().startOfDay.addingTimeInterval(startTime),
                                         actualPositionEnded: Date().startOfDay.addingTimeInterval(endTime),
                                         actualPosition: hour == 7 ? .other : posFrom(ind: ind),
                                         startingTarget: posFrom(ind: ind),
                                         startingTimeRemaining: 0.0,
                                         bmmMonitoringState: PatientMonitorState.onResume.rawValue,
                                         bmmPauseReason: "",
                                         isWrongPosition: hour == 7,
                                         hospitalRoomBedId: "",
                                         mqttTopicStr: "",
                                         updateId: "",
                                         headOfBedAngle: 15,
                                         turnAngle: 10,
                                         endingTargetPosition: "",
                                         mock: true)
                logs.append(log)

                startTime = endTime
                endTime += 1.5 * .secondsPerHour
            }

            let log = ALTActivityLog(session: ALTSession.dev,
                                     actualPositionStarted: Date().startOfDay.addingTimeInterval(startTime),
                                     actualPositionEnded: Date().startOfDay.addingTimeInterval(endTime),
                                     actualPosition: posFrom(ind: ind),
                                     startingTarget: posFrom(ind: ind),
                                     startingTimeRemaining: 0.0,
                                     bmmMonitoringState: hour == 9 ? PatientMonitorState.onPause.rawValue : PatientMonitorState.onResume.rawValue,
                                     bmmPauseReason: "",
                                     isWrongPosition: false,
                                     hospitalRoomBedId: "",
                                     mqttTopicStr: "",
                                     updateId: "",
                                     headOfBedAngle: 15,
                                     turnAngle: 10,
                                     endingTargetPosition: "",
                                     mock: true)
            logs.append(log)
            if ind == 2 {
                ind = 0
            } else {
                ind += 1
            }
        }

        return logs
    }
}
