//
//  AnalyticsChartRowView.swift
//  MobilityLab
//
//  Created by Vadym Riznychok on 5/16/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct AnalyticsChartRowView: View {
    private let dayTimeInterval: TimeInterval = .secondsPerDay
    let logs: [ActivityStartEnd]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(logs, id: \.self) { data in
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: timeToWidth(frameWidth: geo.size.width, time: data.startTime))
                        Rectangle()
                            .foregroundColor(data.analyticsColor)
                            .frame(width: timeToWidth(frameWidth: geo.size.width, time: data.endTime - data.startTime))
                        Spacer()
                            .frame(width: timeToWidth(frameWidth: geo.size.width,
                                                      time: (dayTimeInterval - data.endTime)))
                    }
                }
            }
            .background(Color.clear)
        }
    }

    private func timeToWidth(frameWidth: CGFloat, time: TimeInterval) -> CGFloat {
        let widthPerHour = frameWidth / 24
        let hoursToFloat = time / 60 / 60

        return widthPerHour * hoursToFloat
    }

    private func widthToNearest(_ index: Int, width: CGFloat) -> CGFloat {
        let nextStart = logs[index + 1].startTime
        let currentEnd = logs[index].endTime
        return timeToWidth(frameWidth: width, time: nextStart - currentEnd)
    }
}

struct AnalyticsChartRowView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsChartRowView(logs: [
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(2 * 60 * 60),
                endDate: Date().startOfDay.addingTimeInterval(4 * 60 * 60),
                actualPosition: .left,
                targetPosition: .left,
                startTime: 2 * 60 * 60,
                endTime: 4 * 60 * 60,
                isPause: false
            ),
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(6 * 60 * 60),
                endDate: Date().startOfDay.addingTimeInterval(10 * 60 * 60),
                actualPosition: .right,
                targetPosition: .left,
                startTime: 6 * 60 * 60,
                endTime: 10 * 60 * 60,
                isPause: false
            ),
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(10.05 * 60 * 60),
                endDate: Date().startOfDay.addingTimeInterval(14 * 60 * 60),
                actualPosition: .supine,
                targetPosition: .left,
                startTime: 10.05 * 60 * 60,
                endTime: 14 * 60 * 60,
                isPause: false
            ),
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(22.5 * 60 * 60),
                endDate: Date().startOfDay.addingTimeInterval(24 * 60 * 60),
                actualPosition: .left,
                targetPosition: .left,
                startTime: 22.50 * 60 * 60,
                endTime: 24 * 60 * 60,
                isPause: false
            ),
        ])
        .frame(width: 300, height: 60)
        .background(Color.lightAqua)
    }
}
