//
//  WearableInfoView.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 11/22/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct WearableInfoView: View {
    @ObservedObject var patientMonitorDriver: PatientMonitorDriver
    
    @Binding var wearable: Wearable?
    @Binding var isTrackingStr: String
    @Binding var modal: WearablesDriver.WearablesActiveModal?

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    if patientMonitorDriver.isWearableConnected {
                        monitoringImage
                        monitoringText
                    } else {
                        Image(R.image.graySmallDot.name)
                        disconnectedText
                    }
                    Spacer()
                    crossButton
                }
                
                wearableIDText(geo)
                locationText
                Spacer()
                batteryStack
                VStack(spacing: 16) {
                    pauseResumeButton
                    unpairButton
                }
                .padding(.bottom, geo.safeAreaInsets.bottom)
            }
            .padding()
            .background(backgroundView)
            .padding(.bottom, -geo.safeAreaInsets.bottom)
        }
        .background(Color.black.opacity(0.1))
    }

    private var isMonitoring: Bool {
        if isTrackingStr == R.string.localizable.startMonitoring() {
            return false
        } else {
            return true
        }
    }
    private var watchImageOpacity: Double {
        if isMonitoring {
            return 1
        } else {
            return 0.5
        }
    }

    private var batteryDisable: Bool {
        if isMonitoring {
            return false
        } else {
            return true
        }
    }

    private var batteryTimeRemaining: String {
        if wearable!.batteryTimeRemaining == -1 {
            return R.string.localizable.unknownTimeRemaining()
        } else {
            return R.string.localizable.estTimeRemaining(String(wearable!.batteryTimeRemaining))
        }
    }

    @ViewBuilder
    private var batteryStack: some View {
        VStack {
            WearableBatteryDisplay(
                value: CGFloat(Double(wearable!.batteryLvl) / 100.0),
                batteryDisable: batteryDisable
            )
            .frame(width: 48, height: 48)

            batteryLevelText

            batteryTimeText
        }
    }

    @ViewBuilder
    private var monitoringImage: some View {
        Image(isMonitoring ? R.image.greenSmallDot.name : R.image.graySmallDot.name)
    }

    @ViewBuilder
    private var monitoringText: some View {
        Text(isMonitoring ? R.string.localizable.monitoring() : R.string.localizable.paused())
            .font(.custom("Avenir-Roman", size: 16))
            .foregroundColor(isMonitoring ? .green1 : .charcoal3)
    }

    @ViewBuilder
    private var disconnectedText: some View {
        Text("Disconnected")
            .font(.custom("Avenir-Roman", size: 16))
            .foregroundColor(.charcoal3)
    }

    @ViewBuilder
    private var crossButton: some View {
        Button {
            modal = nil
        } label: {
            Image(R.image.cross.name)
        }
    }

    @ViewBuilder
    private func wearableIDText(_ geo: GeometryProxy) -> some View {
        VStack(spacing: 24) {
            Image(R.image.watch.name)
                .resizable()
                .frame(width: geo.size.width * 0.56, height: geo.size.width * 0.56)
                .opacity(watchImageOpacity)
            Text(wearable!.id.formattedId())
                .font(.custom("SFCompactText-Regular", size: 16))
                .foregroundColor(.aqua1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 1000)
                        .stroke(isMonitoring ? Color.aqua1 : Color.charcoal3, lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private var locationText: some View {
        VStack {
            Text(R.string.localizable.location())
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.charcoal1)
            Text(R.string.localizable.chest())
        }
    }

    @ViewBuilder
    private var batteryLevelText: some View {
        HStack(spacing: 4) {
            Text("Battery")
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(.charcoal1)
            Text(String(wearable!.batteryLvl) + "%")
                .font(.custom("Avenir-Roman", size: 14))
                .foregroundColor(.charcoal3)
        }
    }

    @ViewBuilder
    private var batteryTimeText: some View {
        Text(batteryTimeRemaining)
            .font(.custom("Avenir-Roman", size: 14))
            .foregroundColor(.charcoal3)
    }

    @ViewBuilder
    private var pauseResumeButton: some View {
        Button {
            if isMonitoring {
                patientMonitorDriver.pauseReason = .disconnected
                patientMonitorDriver.setTrackingTo(to: false)
            } else {
                patientMonitorDriver.setTrackingTo(to: true)
            }
        } label: {
            Text(isMonitoring ? R.string.localizable.pauseMonitoring() : R.string.localizable.resumeMonitoring())
                .frame(maxWidth: .infinity)
        }
        .disabled(!patientMonitorDriver.isWearableConnected)
        .buttonStyle(isMonitoring ? ALTButtonStyle.altBtnSecondaryBordered() : ALTButtonStyle())
    }

    @ViewBuilder
    private var unpairButton: some View {
        Button {
            // Unpair
            patientMonitorDriver.unpair()
            modal = nil
        } label: {
            Text(R.string.localizable.unpair())
                .frame(maxWidth: .infinity)
        }
        .disabled(!patientMonitorDriver.isWearableConnected)
        .buttonStyle(FlatButtonStyle(.clear(subtype: .destructive)))
    }

    @ViewBuilder
    private var backgroundView: some View {
        Rectangle()
            .fill(Color.white)
            .cornerRadius(24, corners: [.topLeft, .topRight])
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 2,
                x: 0,
                y: 0
            )
    }
}

struct WearableInfoView_Previews: PreviewProvider {
    static var previews: some View {
        WearableInfoView(patientMonitorDriver: PatientMonitorDriver(using: PatientManager.preview),
                         wearable: .constant(Wearable.devWearable),
                         isTrackingStr: .constant(R.string.localizable.unknown()),
                         modal: .constant(nil))
    }
}
