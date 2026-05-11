//
//  ActivitiesViewModel.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 11/1/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

struct ActivitiesViewModel {
    let id: Int64
    let position: PositionalFlagCategory
    let startTime: TimeInterval
    let endTime: TimeInterval
    let isWrong: Bool
    let isPause: Bool
}
