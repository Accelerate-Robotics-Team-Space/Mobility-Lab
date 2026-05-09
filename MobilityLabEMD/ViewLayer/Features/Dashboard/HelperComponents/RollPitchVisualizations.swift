//
//  RollPitchVisualizations.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/25/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct RollPitchVisualizations: View {
    let bmmData: BMMCardData

    @State var rollDegree: Double
    @State var pitchDegree: Double

    var body: some View {
        GeometryReader { geo in
            let aspectRatio = geo.size.width / 231.0
            VStack {
                HStack(alignment: .top, spacing: 0) {
                    VStack {
                        Text("Turn Position")
                            .font(.custom("Avenir", size: aspectRatio * 10))
                            .foregroundColor(.charcoal1)
                        ZStack(alignment: .top) {
                            if bmmData.canShowCompliance {
                                ComplianceCircle(circleLineWidth: aspectRatio * 8.0,
                                                 degree: rollDegree,
                                                 targetPosition: bmmData.targetPos)
                                .frame(width: aspectRatio * 46, height: aspectRatio * 46)
                            }
                            VStack(alignment: .center) {
                                if bmmData.isDisconnected {
                                    Spacer()
                                    ThreeDotsLoading()
                                    Spacer()
                                } else {
                                    Image(R.image.pointerPatientBed.name)
                                        .resizable()
                                        .frame(width: aspectRatio * 19, height: aspectRatio * 23)
                                        .rotationEffect(.degrees(-Double(rollDegree)), anchor: .bottom)
                                    Text(" " + String((abs(Double(rollDegree)).rounded(.down).clean))
                                        .replacingOccurrences(of: "-", with: "") +
                                         "\u{00B0}")
                                    .font(.custom("Avenir-Heavy", size: 10))
                                }
                            }
                        }
                        .onChange(of: bmmData.rollAngle) { rollDegree in
                            withAnimation(.linear(duration: 0.2)) {
                                self.rollDegree = rollDegree
                            }
                        }
                        .onChange(of: bmmData.sensorState) { newSensorState in
                            if newSensorState == .disconnected {
                                withAnimation(.linear(duration: 0.2)) {
                                    self.rollDegree = 0
                                }
                            }
                        }
                        .onChange(of: bmmData.patientState) { newPatientState in
                            if newPatientState == .swappingSensor || newPatientState == .swappingPatch {
                                withAnimation(.linear(duration: 0.2)) {
                                    self.rollDegree = 0
                                }
                            }
                        }
                    }
                    VStack {
                        Spacer()
                        BatteryCapacityView(isAlive: bmmData.isAlive,
                                            bmmBatteryPercentage: bmmData.bmmBatteryPercentage ?? 0,
                                            sensorBatteryPercentage: bmmData.sensorBatteryPercentage,
                                            isStatic: bmmData.isStatic)
                    }
                    VStack(spacing: 0) {
                        Text("Head of Patient")
                            .font(.custom("Avenir", size: aspectRatio * 10))
                            .foregroundColor(.charcoal1)
                        if bmmData.isDisconnected {
                            Spacer()
                            ThreeDotsLoading()
                            Spacer()
                        } else {
                            HeadOfBedImage(angle: pitchDegree, target: bmmData.targetPos)
                                .frame(width: 46, height: 46)
                                .padding(.top, -4)
                            let displayPitchAngle = Double(Double(pitchDegree).truncatingRemainder(dividingBy: 360.0)).rounded().clean
                            Text(String(displayPitchAngle)
                                .replacingOccurrences(of: "-", with: "") + "\u{00B0}") // u{00B0} = 'º' degree symbol
                            .font(.custom("Avenir-Heavy", size: 10))
                            .transition(.opacity)
                        }
                    }
                    .onChange(of: bmmData.pitchAngle) { pitchDegree in
                        withAnimation(.linear(duration: 0.2)) {
                            self.pitchDegree = pitchDegree
                        }
                    }
                    .onChange(of: bmmData.sensorState) { newSensorState in
                        if newSensorState == .disconnected {
                            withAnimation(.linear(duration: 0.2)) {
                                self.pitchDegree = 0
                            }
                        }
                    }
                    .onChange(of: bmmData.patientState) { newPatientState in
                        if newPatientState == .swappingSensor || newPatientState == .swappingPatch {
                            withAnimation(.linear(duration: 0.2)) {
                                self.pitchDegree = 0
                            }
                        }
                    }
                }
                .padding(.horizontal, aspectRatio * 10)
            }
            .frame(width: geo.size.width)
        }
    }
}

struct RollPitchVisualizations_Previews: PreviewProvider {
    static var previews: some View {
        RollPitchVisualizations(bmmData: BMMViewModel().cardData, rollDegree: 2, pitchDegree: 2)
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPadAirEMD()))
    }
}
