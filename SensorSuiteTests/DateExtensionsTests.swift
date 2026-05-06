//
//  DateExtensionsTests.swift
//  SensorSuite BMM Tests
//
//  Created by Vadym Riznychok on 2/27/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

@testable import SensorSuite_BMM
import XCTest

final class DateExtensionsTests: XCTestCase {
    func testDaysBetweenFixedCalendar() throws {
        let calendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = .init(identifier: "pt-BR")
            calendar.timeZone = TimeZone(identifier: "America/Fortaleza")!
            return calendar
        }()

        // diff date 2 hour in past, resulting in 1 day diff
        var currentDate = dateFor(day: 10, hour: 1, min: 0, using: calendar)
        var diffDate = dateFor(day: 9, hour: 23, min: 0, using: calendar)
        XCTAssertEqual(currentDate.dates(between: diffDate, using: calendar), 1)

        // diff date 2 hour in future, resulting in 1 day diff
        currentDate = dateFor(day: 9, hour: 1, min: 0, using: calendar)
        diffDate = dateFor(day: 10, hour: 23, min: 0, using: calendar)
        XCTAssertEqual(currentDate.dates(between: diffDate, using: calendar), 1)

        // diff date 1 minute in past, current date is midnight, resulting in 1 day diff
        currentDate = dateFor(day: 10, hour: 0, min: 0, using: calendar)
        diffDate = dateFor(day: 9, hour: 23, min: 59, using: calendar)
        XCTAssertEqual(currentDate.dates(between: diffDate, using: calendar), 1)

        // diff date 23 hour 59 minute in future, day is same, resulting in 0 day diff
        currentDate = dateFor(day: 10, hour: 0, min: 0, using: calendar)
        diffDate = dateFor(day: 10, hour: 23, min: 59, using: calendar)
        XCTAssertEqual(currentDate.dates(between: diffDate, using: calendar), 0)

        // diff date 2 days 23 hours and 59 minute in future, current day is midnight, day diff is 2, resulting in 2 day diff
        currentDate = dateFor(day: 10, hour: 0, min: 0, using: calendar)
        diffDate = dateFor(day: 12, hour: 23, min: 59, using: calendar)
        XCTAssertEqual(currentDate.dates(between: diffDate, using: calendar), 2)

        // diff date 1 day and 1 minute in past, current day is midnight, day diff is 2, resulting in 2 day diff
        currentDate = dateFor(day: 10, hour: 0, min: 0, using: calendar)
        diffDate = dateFor(day: 8, hour: 23, min: 59, using: calendar)
        XCTAssertEqual(currentDate.dates(between: diffDate, using: calendar), 2)
    }

    func testStartOfDayFixedCalendar() throws {
        let calendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = .init(identifier: "so-SO")
            calendar.timeZone = TimeZone(identifier: "Africa/Djibouti")!
            return calendar
        }()

        // StartOfDay tests, diff date 1 day and 1 minute in past, day diff is 2, resulting in 2 day diff
        var currentDate = calendar.startOfDay(for: dateFor(day: 10, hour: 23, min: 59, using: calendar))
        var diffDate = calendar.startOfDay(for: dateFor(day: 8, hour: 23, min: 59, using: calendar))
        XCTAssertEqual(currentDate.dates(between: diffDate, using: calendar), 2)

        // StartOfDay tests, diff date is 1 minute in past, day diff is 1, resulting in 1 day diff
        currentDate = calendar.startOfDay(for: dateFor(day: 10, hour: 0, min: 0, using: calendar))
        diffDate = calendar.startOfDay(for: dateFor(day: 9, hour: 23, min: 59, using: calendar))
        XCTAssertEqual(currentDate.dates(between: diffDate, using: calendar), 1)

        // StartOfDay tests, diff date 12 hours and 1 minute in past, day diff is 0, resulting in 0 day diff
        currentDate = calendar.startOfDay(for: dateFor(day: 10, hour: 12, min: 00, using: calendar))
        diffDate = calendar.startOfDay(for: dateFor(day: 10, hour: 23, min: 59, using: calendar))
        XCTAssertEqual(currentDate.dates(between: diffDate, using: calendar), 0)

        // StartOfDay tests, diff date 1 day 13 hours and 24 minutes in future, day diff is 1, resulting in 1 day diff
        currentDate = calendar.startOfDay(for: dateFor(day: 10, hour: 10, min: 35, using: calendar))
        diffDate = calendar.startOfDay(for: dateFor(day: 11, hour: 23, min: 59, using: calendar))
        XCTAssertEqual(currentDate.dates(between: diffDate, using: calendar), 1)
    }

    func testDaysBetweenCurrentCalendar() throws {
        // diff date 2 hour in past, resulting in 1 day diff
        var currentDate = dateFor(day: 10, hour: 1, min: 0)
        var diffDate = dateFor(day: 9, hour: 23, min: 0)
        XCTAssertEqual(currentDate.dates(between: diffDate), 1)

        // diff date 2 hour in future, resulting in 1 day diff
        currentDate = dateFor(day: 9, hour: 1, min: 0)
        diffDate = dateFor(day: 10, hour: 23, min: 0)
        XCTAssertEqual(currentDate.dates(between: diffDate), 1)

        // diff date 1 minute in past, current date is midnight, resulting in 1 day diff
        currentDate = dateFor(day: 10, hour: 0, min: 0)
        diffDate = dateFor(day: 9, hour: 23, min: 59)
        XCTAssertEqual(currentDate.dates(between: diffDate), 1)

        // diff date 23 hour 59 minute in future, day is same, resulting in 0 day diff
        currentDate = dateFor(day: 10, hour: 0, min: 0)
        diffDate = dateFor(day: 10, hour: 23, min: 59)
        XCTAssertEqual(currentDate.dates(between: diffDate), 0)

        // diff date 2 days 23 hours and 59 minute in future, current day is midnight, day diff is 2, resulting in 2 day diff
        currentDate = dateFor(day: 10, hour: 0, min: 0)
        diffDate = dateFor(day: 12, hour: 23, min: 59)
        XCTAssertEqual(currentDate.dates(between: diffDate), 2)

        // diff date 1 day and 1 minute in past, current day is midnight, day diff is 2, resulting in 2 day diff
        currentDate = dateFor(day: 10, hour: 0, min: 0)
        diffDate = dateFor(day: 8, hour: 23, min: 59)
        XCTAssertEqual(currentDate.dates(between: diffDate), 2)
    }

    func testStartOfDayCurrentCalendar() throws {
        // StartOfDay tests, diff date 1 day and 1 minute in past, day diff is 2, resulting in 2 day diff
        var currentDate = Calendar.current.startOfDay(for: dateFor(day: 10, hour: 23, min: 59))
        var diffDate = Calendar.current.startOfDay(for: dateFor(day: 8, hour: 23, min: 59))
        XCTAssertEqual(currentDate.dates(between: diffDate), 2)

        // StartOfDay tests, diff date is 1 minute in past, day diff is 1, resulting in 1 day diff
        currentDate = Calendar.current.startOfDay(for: dateFor(day: 10, hour: 0, min: 0))
        diffDate = Calendar.current.startOfDay(for: dateFor(day: 9, hour: 23, min: 59))
        XCTAssertEqual(currentDate.dates(between: diffDate), 1)

        // StartOfDay tests, diff date 12 hours and 1 minute in past, day diff is 0, resulting in 0 day diff
        currentDate = Calendar.current.startOfDay(for: dateFor(day: 10, hour: 12, min: 00))
        diffDate = Calendar.current.startOfDay(for: dateFor(day: 10, hour: 23, min: 59))
        XCTAssertEqual(currentDate.dates(between: diffDate), 0)

        // StartOfDay tests, diff date 1 day 13 hours and 24 minutes in future, day diff is 1, resulting in 1 day diff
        currentDate = Calendar.current.startOfDay(for: dateFor(day: 10, hour: 10, min: 35))
        diffDate = Calendar.current.startOfDay(for: dateFor(day: 11, hour: 23, min: 59))
        XCTAssertEqual(currentDate.dates(between: diffDate), 1)
    }

    private func dateFor(day: Int, hour: Int, min: Int, using calendar: Calendar = .current) -> Date {
        let components = DateComponents(
            calendar: calendar,
            year: 2001,
            month: 1,
            day: day,
            hour: hour,
            minute: min,
            second: 0
        )

        return calendar.date(from: components)!
    }
}
