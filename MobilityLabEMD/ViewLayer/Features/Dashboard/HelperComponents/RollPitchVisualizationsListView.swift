//
//  RollPitchVisualizationsListView.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 11/8/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct RollPitchVisualizationsListView: View {
    let bmmData: BMMCardData

    @State var rollDegree: Double
    @State var pitchDegree: Double

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack(alignment: .top) {
                if bmmData.canShowCompliance {
                    ComplianceCircle(degree: rollDegree, targetPosition: bmmData.targetPos)
                        .frame(width: 46, height: 46)
                        .padding(.leading, -2)
                }

                VStack(alignment: .center) {
                    if bmmData.isDisconnected ||
                        bmmData.patientState == .unassigned ||
                        bmmData.patientState == .noSession {
                        Spacer()
                        ThreeDotsLoading()
                        Spacer()
                    } else {
                        Image(R.image.pointerPatientBed.name)
                            .resizable()
                            .frame(width: 19, height: 23)
                            .rotationEffect(.degrees(-Double(rollDegree)), anchor: .bottom)
                        Text(" " + String((abs(Double(rollDegree)).rounded(.down).clean))
                            .replacingOccurrences(of: "-", with: "") +
                             "\u{00B0}")
                        .font(.custom("Avenir-Heavy", size: 10))
                        .padding(.top, 2)
                    }
                }
            }
            .padding(.top, bmmData.isDisconnected ? 0 : 10)
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
                if newPatientState == .swappingSensor ||
                    newPatientState == .swappingPatch ||
                    newPatientState == .unassigned ||
                    newPatientState == .noSession {
                    withAnimation(.linear(duration: 0.2)) {
                        self.rollDegree = 0
                    }
                }
            }
            VStack(alignment: .center) {
                if bmmData.isDisconnected ||
                    bmmData.patientState == .unassigned ||
                    bmmData.patientState == .noSession {
                    Spacer()
                    ThreeDotsLoading()
                    Spacer()
                } else {
                    HeadOfBedImage(angle: pitchDegree, target: bmmData.targetPos)
                        .padding(.top, -10)
                        .frame(width: 46, height: 46)
                    let displayPitchAngle = Double(Double(pitchDegree).truncatingRemainder(dividingBy: 360.0)).rounded().clean
                    Text(String(displayPitchAngle)
                        .replacingOccurrences(of: "-", with: "") + "\u{00B0}")
                    .font(.custom("Avenir-Heavy", size: 10))
                    .padding(.top, -10)
                    .transition(.opacity)
                }
            }
            .onChange(of: bmmData.pitchAngle) { pitchDegree in
                withAnimation(.linear(duration: 0.5)) {
                    self.pitchDegree = pitchDegree
                }
            }
            .onChange(of: bmmData.sensorState) { newSensorState in
                if newSensorState == .disconnected {
                    withAnimation(.linear(duration: 0.5)) {
                        self.pitchDegree = 0
                    }
                }
            }
            .onChange(of: bmmData.patientState) { newPatientState in
                if newPatientState == .swappingSensor ||
                    newPatientState == .swappingPatch ||
                    newPatientState == .unassigned ||
                    newPatientState == .noSession {
                    withAnimation(.linear(duration: 0.5)) {
                        self.pitchDegree = 0
                    }
                }
            }
        }
    }
}

struct RollPitchVisualizationsListView_Previews: PreviewProvider {
    static var previews: some View {
        RollPitchVisualizationsListView(bmmData: BMMViewModel().cardData, rollDegree: 2, pitchDegree: 2)
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPadAirEMD()))
    }
}
