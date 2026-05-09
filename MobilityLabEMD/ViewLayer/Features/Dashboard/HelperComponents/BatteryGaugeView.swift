//
//  BatteryGaugeView.swift
//  MobilityLab
//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//
import SwiftUI

struct BatteryGaugeView: View {
    let percentage: Int
    let color: Color

    private let barWidth: CGFloat = 16
    private let barHeight: CGFloat = 8

    private let batterySizeBase: CGFloat = 13.5
    private let cornerRadius: CGFloat = 1.0

    private func batteryOffset(for percentage: Int) -> CGFloat {
        return CGFloat((100.0 - Double(percentage)) * -0.07)
    }

    func batterySize(for percentage: Int, _ ratio: CGFloat = 1.0) -> CGFloat {
        CGFloat(ratio * (Double(percentage) / 100.0 * batterySizeBase))
    }

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            Text("\(percentage)%")
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .font(.custom("Avenir-Roman", size: 8))
                .foregroundColor(.black)
            HStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: CGFloat(2))
                        .stroke(Color.black.opacity(0.4), lineWidth: 0.5)
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(color)
                                .frame(width: batterySize(for: percentage),
                                       height: 6)
                                .offset(x: batteryOffset(for: percentage))
                        )
                        .frame(width: barWidth, height: barHeight)
                }
                Circle()
                    .trim(from: 0.25, to: 0.75)
                    .rotation(Angle(degrees: 180))
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 3, height: 3)
            }
        }
    }
}

#Preview("BatteryGaugeView") {
    VStack {
        BatteryGaugeView(percentage: 10, color: BatteryState.critical.color)
        BatteryGaugeView(percentage: 20, color: BatteryState.warning.color)
        BatteryGaugeView(percentage: 50, color: BatteryState.healthy.color)
        BatteryGaugeView(percentage: 100, color: BatteryState.healthy.color)
    }
}
