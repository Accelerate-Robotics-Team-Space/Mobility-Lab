//
//  WearableInfoView.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/31/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct WearableInfoView: View {
    @ObservedObject var wearableViewModel: WearableViewModel
    @ObservedObject var bmmViewModel: BMMViewModel
    
    private var watchImageOpacity: Double {
        if wearableViewModel.wearableState == .monitoring {
            return 1
        } else {
            return 0.5
        }
    }
    private var batteryDisable: Bool {
        if wearableViewModel.wearableState == .monitoring {
            return false
        } else {
            return true
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                if bmmViewModel.currentOpening != .wearable {
                    bmmViewModel.currentOpening = .wearable
                } else {
                    bmmViewModel.currentOpening = .none
                }
            } label: {
                HStack {
                    WearableBatteryDisplay(batteryPercentage: wearableViewModel.batteryPercentage,
                                           isMonitoring: wearableViewModel.wearableState == .monitoring)
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if wearableViewModel.wearableState == .disconnected || wearableViewModel.wearableSerialNum == nil {
                                Image(R.image.graySmallDot.name)
                                Text("Disconnected")
                                    .font(.custom("Avenir-Roman", size: 14))
                                    .foregroundColor(.charcoal3)
                            } else if wearableViewModel.wearableState != .disconnected {
                                Image(wearableViewModel.wearableState == .paused ? R.image.graySmallDot.name : R.image.greenSmallDot.name)
                                Text(wearableViewModel.wearableState == .paused ? R.string.localizable.paused() : R.string.localizable.monitoring())
                                    .font(.custom("Avenir-Roman", size: 14))
                                    .foregroundColor(wearableViewModel.wearableState == .paused ? .charcoal3 : .green1)
                            }
                        }
                        Text(wearableViewModel.wearableSerialNum ?? "Unknown")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(.charcoal1)
                    }
                    .padding()
                    Spacer()
                    Image(R.image.watch.name)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .opacity(batteryDisable || wearableViewModel.wearableState == .disconnected ? 0.5 : 1)
                    Image(R.image.arrowDown.name)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(bmmViewModel.currentOpening == .wearable ? -180 : 0))
                        .animation(.spring(), value: bmmViewModel.currentOpening)
                }
            }
            .frame(height: 64)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            if bmmViewModel.currentOpening == .wearable {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(R.string.localizable.location())
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(.charcoal1)
                        Spacer()
                        Text(wearableViewModel.wearbleLocated?.rawValue ?? "Unknown")
                            .font(.custom("Avenir-Roman", size: 14))
                            .foregroundColor(.charcoal3)
                    }
                    HStack {
                        HStack(spacing: 4) {
                            Text("Battery")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(.charcoal1)
                            if let batteryPercentage = wearableViewModel.batteryPercentage {
                                Text("\(batteryPercentage)" + "%")
                                    .font(.custom("Avenir-Roman", size: 14))
                                    .foregroundColor(.charcoal3)
                            }
                        }
                    }
                }
                .frame(height: 64)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
        }
    }
}

struct WearableInfoView_Previews: PreviewProvider {
    static var previews: some View {
        WearableInfoView(wearableViewModel: WearableViewModel(
            id: "4AA9E270-30C3-ED11-BA77-14CB6532C0D8",
            wearbleLocated: .chest,
            batteryPercentage: 48,
            wearableState: .monitoring,
            wearableSerialNum: "ECFZ-U6-CHZ0"
        ),
                         bmmViewModel: BMMViewModel())
            .frame(width: 375, height: 635)
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
