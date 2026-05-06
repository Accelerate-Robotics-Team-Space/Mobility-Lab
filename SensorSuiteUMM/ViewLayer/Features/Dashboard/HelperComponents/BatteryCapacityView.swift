//
//  BatteryCapacityView.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/25/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

enum BatteryState {
    case healthy
    case warning
    case critical
    case unknown

    var color: Color {
        switch self {
        case .healthy:
            return .green1
        case .warning:
            return .yellow1
        case .critical:
            return .red1
        case .unknown:
            return .gray
        }
    }

    init(percentage: Int?, warningThreshold: Int = 20, criticalThreshold: Int = 10) {
        guard let percentage else {
            self = .unknown
            return
        }
        if percentage <= criticalThreshold {
            self = .critical
        } else if percentage <= warningThreshold {
            self = .warning
        } else {
            self = .healthy
        }
    }
}

struct BatteryCapacityView: View {
    var isAlive: Bool
    var bmmBatteryPercentage: Int?
    var sensorBatteryPercentage: Int?
    var isStatic: Bool
    var bmmBatteryTimeRemaining: Int?
    private let bmmWarningThreshold: Int = 20
    private let sensorWarningThreshold: Int = 50

    private var bmmBatteryState: BatteryState {
        BatteryState(percentage: bmmBatteryPercentage, warningThreshold: bmmWarningThreshold)
    }
    private var sensorBatteryState: BatteryState {
        BatteryState(percentage: sensorBatteryPercentage, warningThreshold: sensorWarningThreshold)
    }

    var body: some View {
        VStack {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    // BMM UI
                    if let percentage = bmmBatteryPercentage, percentage <= bmmWarningThreshold {
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                Image(R.image.bmmPhoneIcon.name)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20)
                                BatteryGaugeView(percentage: percentage, color: bmmBatteryState.color)
                            }
                            if let timeRemaining = bmmBatteryTimeRemaining {
                                Text("Est. \(timeRemaining) hours for BMM")
                                    .font(.custom("Avenir-Roman", size: 12))
                                    .padding(.horizontal)
                                Divider()
                                    .padding(.trailing)
                            }
                        }
                    }

                    // Sensor UI
                    if let percentage = sensorBatteryPercentage {
                        VStack(spacing: 4) {
                            Image(R.image.watch.name)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30)
                                .padding(.vertical, 4)
                            BatteryGaugeView(percentage: percentage, color: sensorBatteryState.color)
                        }
                    }
                }
            }
        }
    }

    init(isAlive: Bool, bmmBatteryPercentage: Int? = nil, sensorBatteryPercentage: Int? = nil, isStatic: Bool, bmmBatteryTimeRemaining: Int? = nil) {
        self.isAlive = isAlive
        self.bmmBatteryPercentage = bmmBatteryPercentage
        self.sensorBatteryPercentage = sensorBatteryPercentage
        self.isStatic = isStatic
        self.bmmBatteryTimeRemaining = bmmBatteryTimeRemaining
    }
}

#Preview {
    HStack(spacing: 50) {
        Group {
            // If BMM only at critical battery threshold
            BatteryCapacityView(isAlive: true, bmmBatteryPercentage: 10, sensorBatteryPercentage: 30, isStatic: false)
            // If Sensor battery is at low but BMM battery is healthy
            BatteryCapacityView(isAlive: true, bmmBatteryPercentage: 50, sensorBatteryPercentage: 15, isStatic: false)
            // If both are above warning battery threshold
            BatteryCapacityView(isAlive: true, bmmBatteryPercentage: 100, sensorBatteryPercentage: 80, isStatic: false)
            // If both are below low battery
            BatteryCapacityView(isAlive: true, bmmBatteryPercentage: 19, sensorBatteryPercentage: 15, isStatic: false)
            // no sensor battery
            BatteryCapacityView(isAlive: true, bmmBatteryPercentage: 80, sensorBatteryPercentage: nil, isStatic: false, bmmBatteryTimeRemaining: 1)
        }
        .padding()
        .border(.black)
    }
}
