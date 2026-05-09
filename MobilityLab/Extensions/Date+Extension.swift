//
//  Date+Extension.swift
//  MobilityLab
//
//  Created by Anton Vishnyak on 4/10/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Date {
    ///  Modified under license from Apple
    ///  https://github.com/hsiaoer/MotionTracking/blob/master/LICENSE.txt
    var millisecondsSince1970: Int64 {
        return Int64((self.timeIntervalSince1970 * 1_000.0).rounded())
    }
    
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
    
    static func fromDateString(dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateString)
    }

    static func withHoursFromNow(_ hours: Int, calendar: Calendar = .autoupdatingCurrent) -> Date {
        Date(timeInterval: TimeInterval(hours) * .secondsPerHour, since: calendar.startOfDay(for: .now))
    }
	
	static var tenMinutes: TimeInterval { return 600 }
	static var oneHourTimeInterval: TimeInterval {
		return 3600
	}
	
	static var twoHourTimeInterval: TimeInterval {
		return oneHourTimeInterval * 2
	}

	/// Computes the number of dates changed from the self to  given date.
	///
	/// eg: self = 02/27/2024 - 23:59  PM & endDate = 02/28/2024 - 00:00 - returns 1
	///
	/// self = 02/27/2024 - 00:00  PM & endDate = 02/28/2024 - 00:00 - returns 1
	///
	/// self = 02/27/2024 - 00:00  PM & endDate = 02/28/2024 - 23:59 - returns 1
	/// - Parameters:
	///   - endDate: The end date till which the number of dates changed.
	/// - Returns: Number of dates changed from self to given date
    func dates(between endDate: Date, using calendar: Calendar = .current) -> Int {
        let timeZoneDiff = TimeInterval(calendar.timeZone.secondsFromGMT(for: self))
        let adjustedStart = self.advanced(by: timeZoneDiff)
        let adjustedEnd = endDate.advanced(by: timeZoneDiff)
        guard let start = calendar.ordinality(of: .day, in: .era, for: adjustedStart) else { return 0 }
        guard let end = calendar.ordinality(of: .day, in: .era, for: adjustedEnd) else { return 0 }
        return abs(start - end)
    }
}
