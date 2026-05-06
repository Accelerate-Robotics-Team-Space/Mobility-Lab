//
//  TimeInterval+Extensions.swift
//  SensorSuite
//
//  Created by Josh Franco on 12/10/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
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

    static let secondsPerMinute: TimeInterval = 60
}
