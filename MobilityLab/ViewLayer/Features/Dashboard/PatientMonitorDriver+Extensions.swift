//
//  PatientMonitorDriver+Extensions.swift
//  MobilityLab BMM
//
//  Created by Vadym Riznychok on 6/3/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

extension PatientMonitorDriver {
    func publishBMMDisconnectedLog(lastEndDate: Date?, log: ALTActivityLog) {
        let currentDate = Date()

        /// Compare the two logs with the latest `actualPositionEnded` value in the DB and use that as the previous end date.
        let previousLogEndDate = max(log.actualPositionEnded, lastEndDate ?? log.actualPositionEnded)

        /// Check if the previous log is from yesterday or earlier, and if there is a gap of more than 24 hours. Otherwise, take only today’s log.
        let numberOfDays = previousLogEndDate.dates(between: currentDate)
        if previousLogEndDate < Calendar.current.startOfDay(for: currentDate),
           numberOfDays >= 1 && numberOfDays < 30 {
            var dateStarted = previousLogEndDate
            var dateEnded = Calendar.current.startOfDay(for: previousLogEndDate.addingTimeInterval(.secondsPerDay))
            // Send log for each previous day that BMM was in inactive state
            for _ in 1...numberOfDays {
                createAndSendCrashLog(
                    started: dateStarted,
                    ended: dateEnded,
                    lastLog: log
                )
                dateStarted = dateEnded
                dateEnded = dateStarted.addingTimeInterval(.secondsPerDay)
            }

            // Send log for today's inactive time
            createAndSendCurrentCrashLog(
                started: dateStarted,
                ended: currentDate,
                lastLog: log
            )
        } else {
            // Send log for today's inactive time
            createAndSendCurrentCrashLog(
                started: previousLogEndDate,
                ended: currentDate,
                lastLog: log
            )
        }
    }

    private func createAndSendCrashLog(started: Date, ended: Date, lastLog: ALTActivityLog) {
        let activityLog = createCrashLog(started: started, ended: ended, lastLog: lastLog)
        mqttService.publish(
            activityLog.publishable(bmmName: userDefaults.defaultingBaseStationFromApple).toData(),
            to: activityLog.mqttTopicStr,
            isRetained: false,
            qos: .atLeastOnce,
            result: nil
        )
        activityLogRepository.saveToDB(activityLog)
    }

    func createCrashLog(started: Date, ended: Date, lastLog: ALTActivityLog) -> ALTActivityLog {
        let structure = DataFeedTopics.sessionObservation(
            facilityID: userDefaults.facilityId,
            baseStationGuid: userDefaults.baseStationGuid,
            wearableGuuid: UUID()
        ).structure
        return ALTActivityLog(
            session: patientManager.session!.currentSession,
            actualPositionStarted: started,
            actualPositionEnded: ended,
            actualPosition: .left,
            startingTarget: PositionalFlagCategory(lastLog.startingTargetPosition),
            startingTimeRemaining: lastLog.startingTimeRemaining,
            endingTimeRemaining: lastLog.endingTimeRemaining,
            bmmMonitoringState: PatientMonitorState.onPause.rawValue,
            bmmPauseReason: PauseReason.crash.rawValue,
            isWrongPosition: false,
            hospitalRoomBedId: lastLog.hospitalRoomBedId,
            mqttTopicStr: structure,
            updateId: UUID().uuidString,
            headOfBedAngle: 0,
            turnAngle: 0,
            endingTargetPosition: ""
        )
    }
}
