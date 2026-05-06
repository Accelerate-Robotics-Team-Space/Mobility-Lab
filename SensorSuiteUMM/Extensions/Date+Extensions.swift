//
//  Date+Extensions.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 12/28/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Date {
    private static var formatter = DateFormatter()
    static var now: Date {
        Date()
    }
    
    ///  Modified under license from Apple
    ///  https://github.com/hsiaoer/MotionTracking/blob/master/LICENSE.txt
    var millisecondsSince1970: Int64 {
        return Int64((self.timeIntervalSince1970 * 1_000.0).rounded())
    }
    
    var shortFormatted: String {
        Self.formatter.dateFormat = "h:mm a"
        Self.formatter.timeZone = TimeZone.current
        return Self.formatter.string(from: self)
    }
    
    var formattedDate: String {
        Self.formatter.dateFormat = "yyyy-MM-dd"
        Self.formatter.timeZone = TimeZone.current
        return Self.formatter.string(from: self)
    }

    var startOfDay: Date {
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self) ?? Date()
    }

    var endOfDay: Date {
        return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? Date()
    }

    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    static func fromDateString(dateString: String) -> Date? {
        Self.formatter.dateFormat = "yyyy-MM-dd"
        Self.formatter.timeZone = TimeZone.current
        return Self.formatter.date(from: dateString)
    }

    var timeSinceStartOfDay: TimeInterval {
        return timeIntervalSince(startOfDay)
    }
}
