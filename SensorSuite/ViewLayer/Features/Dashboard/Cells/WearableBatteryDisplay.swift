//
//  WearableBatteryDisplay.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 11/10/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct WearableBatteryDisplay: View {
    var value: CGFloat
    var batteryDisable: Bool
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .stroke(lineWidth: 6)
                    .foregroundColor(Color.errigalWhite)
                Circle()
                    .trim(from: 0.0, to: self.value)
                    .stroke(style: StrokeStyle(lineWidth: 6))
                    .foregroundColor(batteryDisable ? .charcoal3 : .yellow1)
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
        WearableBatteryDisplay(value: 0.75, batteryDisable: false)
    }
}
