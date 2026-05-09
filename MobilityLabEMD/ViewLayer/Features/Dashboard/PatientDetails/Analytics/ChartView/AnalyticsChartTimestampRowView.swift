//
//  AnalyticsChartTimestampRowView.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 4/3/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct AnalyticsChartTimestampRowView: View {
    private let dayTimeInterval: TimeInterval = .secondsPerDay
    let timestamps: [TurnTimestamp]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(timestamps, id: \.self) { timestamp in
                    HStack(alignment: .center, spacing: 0) {
                        Spacer()
                            .frame(width: timeToWidth(frameWidth: geo.size.width, time: timestamp.turnTime.timeSinceStartOfDay))
                        Image(R.image.turnStartIndicator.name)
                            .resizable()
                            .frame(width: 10, height: 10)
                        Spacer()
                            .frame(width: timeToWidth(frameWidth: geo.size.width, time: (dayTimeInterval - timestamp.turnTime.timeSinceStartOfDay)))
                    }
                    .offset(x: -5.0)
                }
            }
            .background(Color.clear)
        }
    }

    private func timeToWidth(frameWidth: CGFloat, time: TimeInterval) -> CGFloat {
        let widthPerHour = frameWidth / 24
        let hoursToFloat = CGFloat(time / 60 / 60)

        return widthPerHour * hoursToFloat
    }
}

#Preview {
    AnalyticsChartTimestampRowView(timestamps: [
        TurnTimestamp(turnTime: Date().startOfDay.addingTimeInterval(2 * 60 * 60),
                      targetPosition: .left),
        TurnTimestamp(turnTime: Date().startOfDay.addingTimeInterval(8 * 60 * 60),
                      targetPosition: .left),
        TurnTimestamp(turnTime: Date().startOfDay.addingTimeInterval(10.05 * 60 * 60),
                      targetPosition: .left),
        TurnTimestamp(turnTime: Date().startOfDay.addingTimeInterval(22.5 * 60 * 60),
                      targetPosition: .left),
    ])
    .frame(width: 300, height: 60)
    .background(Color.lightAqua)
}
