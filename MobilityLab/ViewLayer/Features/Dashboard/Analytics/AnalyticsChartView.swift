//
//  AnalyticsChartView.swift
//  MobilityLab
//
//  Created by Vadym Riznychok on 5/15/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct AnalyticsChartView: View {
    var logs: [ActivityStartEnd]

    @Injected(\.userDefaults) private var userDefaults

    @State private var zoomScale: CGFloat = 1.0
    @State private var scrollViewContentWidth: CGFloat = 1.0
    @State private var scrollViewContentOffset: CGPoint = .zero

    private var timeDivision: Int {
        guard zoomScale < 8.0 else { return 23 }
        return (24 / userDefaults.turnProtocol!.hoursInt) - 1
    }
    private var blockDivision: Int {
        guard zoomScale < 8.0 else { return 23 }
        return userDefaults.turnProtocol == .Q4 ? 2 : 3
    }
    private var blockLenght: Int {
        return (24 / (blockDivision + 1))
    }

    var body: some View {
        GeometryReader { geo in
            UIScrollViewWrapper(
                contentWidth: $scrollViewContentWidth,
                contentOffset: $scrollViewContentOffset,
                lastContentOffset: .constant(.zero),
                content: {
                    VStack(spacing: 0, content: {
                        ForEach((0...4), id: \.self) { hIndex in
                            if hIndex != 4 {
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

                                    rowForIndex(hIndex)
                                    if hIndex < 3 {
                                        AnalyticsChartExpectedRowView(logs: logsWrong(for: hIndex).sorted(by: { $0.startTime < $1.startTime }))
                                    }
                                }
                            } else {
                                AnalyticsTimelineView(
                                    timeDivision: timeDivision,
                                    blockDivision: blockDivision,
                                    blockLenght: blockLenght,
                                    isZoomed: zoomScale >= 8.0
                                )
                            }
                        }
                    })
                    .frame(width: geo.size.width * zoomScale, height: geo.size.height)
                    .onAppear(perform: {
                        scrollViewContentWidth = geo.size.width * zoomScale
                    })
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2, coordinateSpace: .local) { location in
                        if zoomScale != 1 {
                            zoomScale = 1
                        } else {
                            zoomScale = 16
                        }
                        scrollViewContentWidth = geo.size.width * zoomScale
                        let newOffset = (zoomScale * location.x) - location.x
                        scrollViewContentOffset = CGPoint(x: newOffset, y: 0)
                    }
                }
            )
        }
    }

    private func rowForIndex(_ index: Int) -> some View {
        let data: [ActivityStartEnd] = dataForRow(index)
        return AnalyticsChartRowView(logs: data.sorted(by: { $0.startTime < $1.startTime }))
    }

    private func dataForRow(_ index: Int) -> [ActivityStartEnd] {
        switch index {
        case 0:
            return logs.filter { (activity: ActivityStartEnd) -> Bool in
                activity.filtered(.left)
            }
        case 1:
            return logs.filter { (activity: ActivityStartEnd) -> Bool in
                activity.filtered(.supine)
            }
        case 2:
            return logs.filter { (activity: ActivityStartEnd) -> Bool in
                activity.filtered(.right)
            }
        case 3:
            return logs.filter { (activity: ActivityStartEnd) -> Bool in
                activity.filtered(.other)
            }
        default:
            return [ActivityStartEnd]()
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

    init(logs: [ActivityStartEnd]) {
        self.logs = logs
    }
}

private extension ActivityStartEnd {
    enum Filter {
        case left
        case supine
        case right
        case other
    }

    func filtered(_ filter: ActivityStartEnd.Filter) -> Bool {
        switch filter {
        case .left:
            guard isPause == false else {
                return false
            }
            return [.left, .partialLeft].contains(actualPosition)
        case .supine:
            guard isPause == false else {
                return false
            }
            return actualPosition == .supine
        case .right:
            guard isPause == false else {
                return false
            }
            return [.right, .partialRight].contains(actualPosition)
        case .other:
            return actualPosition == .other || isPause
        }
    }
}

struct AnalyticsChartView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsChartView(logs: [
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(0),
                endDate: Date().startOfDay.addingTimeInterval(2 * 60 * 60),
                actualPosition: .left,
                targetPosition: .left,
                startTime: 0,
                endTime: 2 * 60 * 60,
                isPause: false
            ),
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(2 * 60 * 60),
                endDate: Date().startOfDay.addingTimeInterval(4 * 60 * 60),
                actualPosition: .right,
                targetPosition: .right,
                startTime: 2 * 60 * 60,
                endTime: 4 * 60 * 60,
                isPause: false
            ),
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(4 * 60 * 60),
                endDate: Date().startOfDay.addingTimeInterval(6 * 60 * 60),
                actualPosition: .supine,
                targetPosition: .supine,
                startTime: 4 * 60 * 60,
                endTime: 6 * 60 * 60,
                isPause: false
            ),
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(6 * 60 * 60),
                endDate: Date().startOfDay.addingTimeInterval(8 * 60 * 60),
                actualPosition: .right,
                targetPosition: .left,
                startTime: 6 * 60 * 60,
                endTime: 8 * 60 * 60,
                isPause: false
            ),
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(8 * 60 * 60),
                endDate: Date().startOfDay.addingTimeInterval(10 * 60 * 60),
                actualPosition: .left,
                targetPosition: .right,
                startTime: 8 * 60 * 60,
                endTime: 10 * 60 * 60,
                isPause: false
            ),
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(10 * 60 * 60),
                endDate: Date().startOfDay.addingTimeInterval(12 * 60 * 60),
                actualPosition: .left,
                targetPosition: .supine,
                startTime: 10 * 60 * 60,
                endTime: 12 * 60 * 60,
                isPause: false
            ),
        ])
        .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
