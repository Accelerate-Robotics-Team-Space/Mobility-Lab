//
//  TimeInterval+Extensions.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

extension TimeInterval {
    /// Seconds in a day, without considering leap seconds.
    /// The `Calendar` API should be used where acurate calculations are required
    static let secondsPerDay: TimeInterval = .secondsPerHour * 24 // 24 hours

    var formatted: String {
        let intervalInteger = Int(self.rounded())
        let hour = abs(intervalInteger / 3_600)
        let min = abs((intervalInteger % 3_600) / 60)
        let second = abs((intervalInteger % 60) % 60)
        
        let hourStr = hour < 10 ? "0\(hour)" : "\(hour)"
        let minStr = min < 10 ? "0\(min)" : "\(min)"
        let secStr = second < 10 ? "0\(second)" : "\(second)"
        
        return "\(hourStr):\(minStr):\(secStr)"
    }

    static let secondsPerHour: TimeInterval = 3_600
}
