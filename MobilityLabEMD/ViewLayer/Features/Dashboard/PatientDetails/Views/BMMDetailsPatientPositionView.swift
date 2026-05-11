//
//  BMMDetailsPatientPositionView.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 11/29/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BMMDetailsPatientPositionView: View {
    @ObservedObject var bmmViewModel: BMMViewModel
    @Binding var rollDegree: Double
    @Binding var pitchDegree: Double

    var body: some View {
        HStack(spacing: 20) {
            Spacer()
            VStack(spacing: 40) {
                Text("Turn Position")
                    .font(.custom("Avenir", size: 14))
                    .foregroundColor(.charcoal1)
                ZStack(alignment: .top) {
                    if bmmViewModel.cardData.canShowCompliance {
                        ComplianceCircle(circleLineWidth: 12,
                                         degree: rollDegree,
                                         targetPosition: bmmViewModel.cardData.targetPos)
                        .environmentObject(bmmViewModel.turningProtocol)
                        .frame(width: 84, height: 84)
                    }
                    VStack {
                        if !bmmViewModel.cardData.canShowPatientDetails
                            || bmmViewModel.patientState == .noSession
                            || bmmViewModel.patientState == .swappingPatch
                            || bmmViewModel.patientState == .swappingSensor
                            || bmmViewModel.cardData.sensorState == .disconnected
                            || bmmViewModel.bmmState == .disconnected {
                            Spacer()
                            ThreeDotsLoading()
                            Spacer()
                        } else {
                            Image(R.image.pointerPatientBed.name)
                                .resizable()
                                .frame(width: 36, height: 42)
                                .scaledToFit()
                                .rotationEffect(.degrees(-rollDegree), anchor: .bottom)
                            Text(" " + String((abs(rollDegree).rounded(.down).clean))
                                .replacingOccurrences(of: "-", with: "") +
                                 "\u{00B0}")
                            .padding(.top, 10)
                            .transition(.opacity)
                        }
                    }
                }
                .onReceive(bmmViewModel.$rollAngle) { rollDegree in
                    withAnimation(.linear(duration: 0.5)) {
                        self.rollDegree = rollDegree
                    }
                }
            }
            .frame(width: 100, height: 100)
            Spacer()
            if bmmViewModel.patientState == .swappingPatch
                || bmmViewModel.patientState == .swappingSensor
                || bmmViewModel.cardData.sensorState == .disconnected
                || bmmViewModel.bmmState == .disconnected {
                Image(R.image.swapping.name)
            } else {
                VStack {
                    Image(bmmViewModel.cardData.targetPos?.imageStr ?? R.image.positionUnknown.name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.top, 46)
                    Text(R.string.localizable.patientMonitorTargetPosition(bmmViewModel.cardData.targetPos?.description ?? "Unknown Position"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .font(.custom("Avenir-Heavy", size: 24))
                }
            }
            Spacer()
            VStack {
                Text("Head of Patient")
                    .font(.custom("Avenir", size: 14))
                    .foregroundColor(.charcoal1)
                if !bmmViewModel.cardData.canShowPatientDetails
                    || bmmViewModel.patientState == .noSession
                    || bmmViewModel.patientState == .swappingPatch
                    || bmmViewModel.patientState == .swappingSensor
                    || bmmViewModel.cardData.sensorState == .disconnected
                    || bmmViewModel.bmmState == .disconnected {
                    Spacer()
                    ThreeDotsLoading()
                    Spacer()
                } else {
                    VStack {
                        HeadOfBedImage(angle: pitchDegree, target: bmmViewModel.cardData.targetPos)
                            .frame(height: 80)
                        let displayPitchAngle = Double(pitchDegree.truncatingRemainder(dividingBy: 360.0)).rounded().clean
                        Text(String(displayPitchAngle)
                            .replacingOccurrences(of: "-", with: "") + "\u{00B0}")
                        .transition(.opacity)
                    }
                    .onReceive(bmmViewModel.$pitchAngle) { pitchDegree in
                        withAnimation(.linear(duration: 0.5)) {
                            self.pitchDegree = pitchDegree
                        }
                    }
                }
            }
            .frame(width: 100, height: 100)
            Spacer()
        }
    }
}

struct BMMDetailsPatientPositionView_Previews: PreviewProvider {
    static var previews: some View {
        BMMDetailsPatientPositionView(bmmViewModel: BMMViewModel(), rollDegree: .constant(1), pitchDegree: .constant(1))
    }
}
