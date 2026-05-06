//
//  AnalyticsChartView.swift
//  SensorSuite
//
//  Created by Vadym Riznychok on 5/15/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct AnalyticsChartView: View {
    @EnvironmentObject var driver: DashboardDriver

    @State private var zoomScale: CGFloat = 1.0
    @State private var lastMagnification: CGFloat = 1.0
    @State private var touchCache: CGFloat?
    @State private var offsetCache: CGFloat?
    @State private var timer: Timer?
    @State private var size: CGSize = .zero
    @State private var scrollViewContentWidth: CGFloat = 1.0
    @State private var scrollViewContentOffset: CGPoint = .zero
    @State private var scrollViewLastContentOffset: CGPoint = .zero

    var logs: [ActivityStartEnd]
    var timestamps: [TurnTimestamp]
    private var turnProtocol: TurnProtocol {
        driver.currentBMM?.turnProtocol ?? .Q2
    }
    private var timeDivision: Int {
        guard zoomScale < 8.0 else { return 23 }
        switch turnProtocol {
        case .Q2:
            return 11
        case .Q3:
            return 7
        case .Q4:
            return 5
        }
    }

    var body: some View {
        GeometryReader { geo in
            UIScrollViewWrapper(contentWidth: $scrollViewContentWidth, contentOffset: $scrollViewContentOffset,
                                lastContentOffset: $scrollViewLastContentOffset, content: {
                VStack(spacing: 0, content: {
                    ForEach((0...4), id: \.self) { hIndex in
                        if hIndex != 4 {
                            rowForIndex(hIndex)
                        } else {
                            AnalyticsTimelineView(timeDivision: timeDivision, 
                                                  turnHours: turnProtocol.hoursInt,
                                                  isZoomed: zoomScale >= 8.0)
                        }
                    }
                })
                .frame(width: geo.size.width * zoomScale, height: geo.size.height)
                .onAppear(perform: {
                    scrollViewContentWidth = geo.size.width * zoomScale
                })
                .contentShape(Rectangle())
                .apply({ view in
                    if #available(iOS 17.0, *) {
                        view.gesture(MagnifyGesture()
                            .onEnded({ gesture in
                                lastMagnification = safeMagnification(gesture.magnification)
                                touchCache = nil
                                offsetCache = nil
                                startZoomResetTimer()
                            })
                            .onChanged({ gesture in
                                if touchCache == nil {
                                    touchCache = gesture.startLocation.x - scrollViewLastContentOffset.x
                                    offsetCache = gesture.startLocation.x
                                }
                                zoomScale = safeMagnification(gesture.magnification)
                                guard zoomScale > 1.0 else {
                                    self.resetScrollViewSize()
                                    return
                                }

                                scrollViewContentWidth = geo.size.width * zoomScale
                                let scaledOffset = (offsetCache! / lastMagnification)
                                let newOffset = (scaledOffset * zoomScale) - touchCache!
                                scrollViewContentOffset = CGPoint(x: newOffset, y: 0)
                            }))
                    }
                })
                .onTapGesture(count: 2, coordinateSpace: .local) { location in
                    zoomScale = zoomScale != 1 ? 1 : 8
                    lastMagnification = lastMagnification != 1 ? 1 : 8

                    scrollViewContentWidth = geo.size.width * zoomScale
                    let newOffset = (zoomScale * location.x) - location.x
                    scrollViewContentOffset = CGPoint(x: newOffset, y: 0)
                    startZoomResetTimer()
                }
            })
            .onAppear {
                size = geo.size
            }
        }
    }
    
    private func rowForIndex(_ index: Int) -> some View {
        return AnalyticsChartRowView(logs: logs, timestamps: timestamps, index: index, timeDivision: timeDivision)
    }

    private func safeMagnification(_ magnification: CGFloat) -> CGFloat {
        let rawMagnification = magnification > 1.0 ? (magnification + lastMagnification - 1) : (magnification * (lastMagnification - 1))
        return max(1.0, min(16.0, rawMagnification))
    }

    private func startZoomResetTimer() {
        self.timer?.invalidate()
        if zoomScale != 1 {
            self.timer = Timer.scheduledTimer(withTimeInterval: 120.0, repeats: false, block: { _ in
                self.zoomScale = 1
                self.lastMagnification = 1
                self.resetScrollViewSize()
            })
        }
    }

    private func resetScrollViewSize() {
        scrollViewContentOffset = .zero
        scrollViewContentWidth = size.width
    }

    init(logs: [ActivityStartEnd], timestamps: [TurnTimestamp]) {
        self.logs = logs
        self.timestamps = timestamps
    }
}

struct AnalyticsChartView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsChartView(logs: [
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(0),
                endDate: Date().startOfDay.addingTimeInterval(2 * 60 * 60),
                actualPosition: .right,
                targetPosition: .left,
                startTime: 0 * 60 * 60,
                endTime: 2 * 60 * 60,
                isPause: false
            ),
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(2 * 60 * 60),
                endDate: Date().startOfDay.addingTimeInterval(4 * 60 * 60),
                actualPosition: .left,
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
                actualPosition: .supine,
                targetPosition: .left,
                startTime: 6 * 60 * 60,
                endTime: 8 * 60 * 60,
                isPause: false
            ),
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(8 * 60 * 60),
                endDate: Date().startOfDay.addingTimeInterval(10 * 60 * 60),
                actualPosition: .supine,
                targetPosition: .right,
                startTime: 8 * 60 * 60,
                endTime: 10 * 60 * 60,
                isPause: false
            ),
            ActivityStartEnd(
                startDate: Date().startOfDay.addingTimeInterval(10 * 60 * 60),
                endDate: Date().startOfDay.addingTimeInterval(12 * 60 * 60),
                actualPosition: .supine,
                targetPosition: .supine,
                startTime: 10 * 60 * 60,
                endTime: 12 * 60 * 60,
                isPause: false
            ),
        ], timestamps: [])
        .environmentObject(DashboardDriver())
        .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
