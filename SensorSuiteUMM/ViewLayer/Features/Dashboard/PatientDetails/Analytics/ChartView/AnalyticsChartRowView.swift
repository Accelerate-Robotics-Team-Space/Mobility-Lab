//
//  AnalyticsChartRowView.swift
//  SensorSuite BMM
//
//  Created by Vadym Riznychok on 7/23/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct AnalyticsChartRowView: View {
    var logs: [ActivityStartEnd]
    var timestamps: [TurnTimestamp]
    var index: Int
    var timeDivision: Int

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                ForEach((0...timeDivision), id: \.self) { vIndex in
                    Rectangle()
                        .overlay(EdgeBorder(width: 1, edges: vIndex == timeDivision ? [.leading, .trailing] : [.leading])
                            .stroke(Color.charcoal4.opacity(0.3), lineWidth: 1))
                        .foregroundColor(.clear)
                }
            }
            .overlay(EdgeBorder(width: 1, edges: [.top])
                .stroke(Color.charcoal4.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4])))
            rowForIndex(index)
            if index < 3 {
                AnalyticsChartExpectedRowView(logs: logsWrong(for: index).sorted(by: { $0.startTime < $1.startTime }))
                VStack {
                    Spacer()
                    AnalyticsChartTimestampRowView(timestamps: timestamps(for: index)
                        .sorted(by: { $0.turnTime.timeSinceStartOfDay < $1.turnTime.timeSinceStartOfDay }))
                        .frame(height: 10)
                    Spacer()
                }
            }
        }
    }

    private func rowForIndex(_ index: Int) -> some View {
        let data = dataForRow(index)
        return AnalyticsChartActualRowView(logs: data.sorted(by: { $0.startTime < $1.startTime }))
    }

    private func dataForRow(_ index: Int) -> [ActivityStartEnd] {
        switch index {
        case 0:
            return logs.filter { ($0.actualPosition == .left || $0.actualPosition == .partialLeft) && $0.isPause == false }
        case 1:
            return logs.filter { $0.actualPosition == .supine && $0.isPause == false }
        case 2:
            return logs.filter { ($0.actualPosition == .right || $0.actualPosition == .partialRight) && $0.isPause == false }
        case 3:
            return logs.filter({ $0.isPause == true || $0.actualPosition == .other })
        default:
            return []
        }
    }

    private func logsWrong(for index: Int) -> [ActivityStartEnd] {
        guard index < 3 else { return [] }
        let target = [PositionalFlagCategory.left, .supine, .right][index]
        return logs.filter({ log in
            guard log.isWrong == true && log.isPause == false else { return false }
            if log.targetPosition == target { return true }
            return false
        })
    }

    private func timestamps(for index: Int) -> [TurnTimestamp] {
        switch index {
        case 0:
            return timestamps.filter { $0.targetPosition == .left }
        case 1:
            return timestamps.filter { $0.targetPosition == .supine }
        case 2:
            return timestamps.filter { $0.targetPosition == .right }
        default:
            return []
        }
    }
}

#Preview {
    AnalyticsChartRowView(logs: [], timestamps: [], index: 0, timeDivision: 3)
}
