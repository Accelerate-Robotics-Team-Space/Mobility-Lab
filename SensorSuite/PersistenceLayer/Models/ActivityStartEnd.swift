//
//  ActivityStartEnd.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 2/15/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation
import SwiftUI

struct ActivityStartEnd: Hashable, Identifiable {
    let id: Int64
    var startDate: Date
    var endDate: Date
    let actualPosition: PositionalFlagCategory
    let targetPosition: PositionalFlagCategory
    var startTime: TimeInterval
    var endTime: TimeInterval
    let isPause: Bool

    init(
        id: Int64? = nil,
        startDate: Date,
        endDate: Date,
        actualPosition: PositionalFlagCategory,
        targetPosition: PositionalFlagCategory,
        startTime: TimeInterval,
        endTime: TimeInterval,
        isPause: Bool
    ) {
        self.id = id ?? {
            var hasher = Hasher()
            hasher.combine(startDate)
            hasher.combine(endDate)
            hasher.combine(actualPosition)
            hasher.combine(targetPosition)
            hasher.combine(isPause)
            return Int64(hasher.finalize())
        }()
        self.startDate = startDate
        self.endDate = endDate
        self.actualPosition = actualPosition
        self.targetPosition = targetPosition
        self.startTime = startTime
        self.endTime = endTime
        self.isPause = isPause
    }

    var isWrong: Bool {
        !actualPosition.isCompliance(with: targetPosition)
    }

    var analyticsColor: Color {
        isPause ? .charcoal3 : (isWrong ? .red3 : actualPosition.analyticsColor)
    }
}
