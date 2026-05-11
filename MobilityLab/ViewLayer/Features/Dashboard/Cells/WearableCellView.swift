//
//  WearableCellView.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 11/9/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct WearableCellView: View {
    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    private(set) var wearable: Wearable
    
    private var batteryDisable: Bool {
        if !patientMonitorDriver.isTracking {
            return true
        } else {
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                WearableBatteryDisplay(
                    value: CGFloat(Double(wearable.batteryLvl) / 100.0),
                    batteryDisable: batteryDisable
                )
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if patientMonitorDriver.isWearableConnected {
                            trackingView
                        } else {
                            disconnectedView
                        }
                    }
                    Text(wearable.id.formattedId())
                        .font(.custom("Avenir-Heavy", size: 16))
                }
                .padding()
                Spacer()
                Image(R.image.watch.name)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .opacity(batteryDisable || !patientMonitorDriver.isWearableConnected ? 0.5 : 1)
            }
            .frame(height: 64)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            Divider()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    locationText
                    Spacer()
                   wearableDescription
                }
                HStack {
                    batteryText
                    Spacer()
                    batteryTimeRemainingView
                }
            }
            .frame(height: 64)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 1)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    @ViewBuilder
    var trackingView: some View {
        Image(!patientMonitorDriver.isTracking ? R.image.graySmallDot.name : R.image.greenSmallDot.name)
        Text(!patientMonitorDriver.isTracking ? R.string.localizable.paused() : R.string.localizable.monitoring())
            .font(.custom("Avenir-Roman", size: 14))
            .foregroundColor(!patientMonitorDriver.isTracking ? .charcoal3 : .green1)
    }

    @ViewBuilder
    var disconnectedView: some View {
        Image(R.image.graySmallDot.name)
        Text("Disconnected")
            .font(.custom("Avenir-Roman", size: 14))
            .foregroundColor(.charcoal3)
    }

    @ViewBuilder
    var locationText: some View {
        Text(R.string.localizable.location())
            .font(.custom("Avenir-Heavy", size: 14))
            .foregroundColor(.charcoal1)
    }

    @ViewBuilder
    var wearableDescription: some View {
        Text(wearable.location.description)
            .font(.custom("Avenir-Roman", size: 14))
            .foregroundColor(.charcoal3)
    }

    @ViewBuilder
    var batteryText: some View {
        HStack(spacing: 4) {
            Text("Battery")
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(.charcoal1)
            Text(String(wearable.batteryLvl) + "%")
                .font(.custom("Avenir-Roman", size: 14))
                .foregroundColor(.charcoal3)
        }
    }

    @ViewBuilder
    var batteryTimeRemainingView: some View {
        let initialBatteryTimeEstimation = (18.0 * Double(wearable.batteryLvl) / 100.0).rounded(.down).clean
        Text(
            wearable.batteryTimeRemaining == -1
             ? R.string.localizable.estTimeRemaining(String(initialBatteryTimeEstimation))
             : R.string.localizable.estTimeRemaining(String(wearable.batteryTimeRemaining))
        )
        .font(.custom("Avenir-Roman", size: 14))
        .foregroundColor(.charcoal3)
    }
}

struct WearableCellView_Previews: PreviewProvider {
    static var previews: some View {
        WearableCellView(wearable: Wearable.devWearable)
    }
}
