//
//  DateFormatter+Extensions.swift
//  SensorSuite UMM
//
//  Created by Vadym Riznychok on 8/7/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

extension DateComponentsFormatter {
    static let briefTime: DateComponentsFormatter = {
        let dateFormatter = DateComponentsFormatter()
        dateFormatter.unitsStyle = .brief
        dateFormatter.allowedUnits = [.hour, .minute]
        return dateFormatter
    }()

    static let positionalBriefTime: DateComponentsFormatter = {
        let dateFormatter = DateComponentsFormatter()
        dateFormatter.unitsStyle = .positional
        dateFormatter.zeroFormattingBehavior = .pad
        dateFormatter.allowedUnits = [.hour, .minute, .second]
        return dateFormatter
    }()
}

extension DateFormatter {
    static let regDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter
    }()

    static let analyticsDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
