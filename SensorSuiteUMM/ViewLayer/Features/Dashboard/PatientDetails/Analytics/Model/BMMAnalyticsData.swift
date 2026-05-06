//
//  BMMAnalyticsData.swift
//  SensorSuite UMM
//
//  Created by Vadym Riznychok on 6/16/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import Foundation

struct BMMAnalyticsData {
    var logs: [ActivityStartEnd] {
        didSet {
            updateCompliance()
            updatePositionDurations()
        }
    }
    var timestamps: [TurnTimestamp]
    var positionDurations: [PositionalFlagCategory: Int] = [:]
    var pausedDuration: Int = 0
    var wrongDuration: Int = 0
    var totalMonitoring: Int = 0
    var complianceStr: String = " "
	
	var totalPositionDateFormatter: DateComponentsFormatter = {
		let dateFormatter = DateComponentsFormatter()
		dateFormatter.unitsStyle = .positional
		dateFormatter.zeroFormattingBehavior = .pad
		dateFormatter.allowedUnits = [.hour, .minute, .second]
		return dateFormatter
	}()
	
	var complianceNumberFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.maximumFractionDigits = 0
		return formatter
	}()

    init(logs: [ActivityStartEnd], timestamps: [TurnTimestamp]) {
        self.logs = logs
        self.timestamps = timestamps
        self.updateCompliance()
        self.updatePositionDurations()
    }

    init() {
        logs = []
        timestamps = []
    }

    func totalPositionDuration(_ position: PositionalFlagCategory?) -> String {
        guard let position = position else { return "00:00:00" }
        var duration = TimeInterval(positionDurations[position] ?? 0)
        if position == .left {
            duration += TimeInterval(positionDurations[.partialLeft] ?? 0)
        } else if position == .right {
            duration += TimeInterval(positionDurations[.partialRight] ?? 0)
        }
        return totalPositionDateFormatter.string(from: duration)?.replacingOccurrences(of: "-", with: "") ?? "Time Format Error"
    }

    func totalMonitoringDuration() -> String {
        return totalPositionDateFormatter.string(from: TimeInterval(totalMonitoring))?.replacingOccurrences(of: "-", with: "") ?? "Time Format Error"
    }

    mutating func updateCompliance() {
        var validDuration: Double = 0
        var totalDuration: Double = 0
        for log in logs where !log.isPause {
            totalDuration += Double(log.endTime - log.startTime)
            if !log.isWrong {
                validDuration += Double(log.endTime - log.startTime)
            }
        }
        if validDuration == 0, totalDuration == 0 {
            complianceStr = " "
            return
        }
        
        let compliance = NSNumber(value: validDuration / totalDuration * 100)
        let complianceString = complianceNumberFormatter.string(from: compliance) ?? "0"
        complianceStr = "\(complianceString)%"
    }

    mutating func updatePositionDurations() {
        var positionsDur: [PositionalFlagCategory: Int] = [:]
        var pauseDur: Int = 0
        var wrongDur: Int = 0
        var totalDur: Int = 0

        let sortedLogs = logs.sorted(by: { $0.startTime < $1.startTime })
        sortedLogs
            .forEach { activity in
                // Position duration calculations
                let activityDuration = Int(activity.endTime - activity.startTime)
                if !activity.isPause && !activity.isWrong {
                    positionsDur[activity.actualPosition] = (positionsDur[activity.actualPosition] ?? 0) + activityDuration
                }

                pauseDur += activity.isPause ? activityDuration : 0
                wrongDur += activity.isWrong && !activity.isPause ? activityDuration : 0
                totalDur += activity.isPause ? 0 : activityDuration
            }
        positionDurations = positionsDur
        pausedDuration = pauseDur
        wrongDuration = wrongDur
        totalMonitoring = totalDur
    }
}
