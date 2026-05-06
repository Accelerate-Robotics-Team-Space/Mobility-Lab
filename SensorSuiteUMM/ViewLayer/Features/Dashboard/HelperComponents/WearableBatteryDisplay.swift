//
//  WearableBatteryDisplay.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/31/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct WearableBatteryDisplay: View {
    var batteryPercentage: Int?
    var isMonitoring: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .stroke(lineWidth: 6)
                    .foregroundColor(Color.errigalWhite)
                Circle()
                    .trim(from: 0.0, to: CGFloat(Double(batteryPercentage ?? 0) / 100.0))
                    .stroke(style: StrokeStyle(lineWidth: 6))
                    .foregroundColor(isMonitoring ? .yellow1 : .charcoal3)
                    .rotationEffect(.degrees(-90))
                Image(R.image.battery.name)
                    .resizable()
                    .frame(width: geo.size.width / 2, height: geo.size.width / 2)
            }
        }
    }
}

struct WearableBatteryDisplay_Previews: PreviewProvider {
    static var previews: some View {
        WearableBatteryDisplay(batteryPercentage: 100, isMonitoring: true)
    }
}
