//
//  PairingWearableStepTwo.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 10/6/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct PairingWearableStepTwo: View {
    @Injected(\.patchTrackingService) private var patchService: PatchTrackingServiceProtocol
    @Injected(\.userDefaults) private var userDefaults

    @EnvironmentObject var dashboardDriver: DashboardDriver
    @EnvironmentObject var patientDriver: PatientMonitorDriver
    @Binding var pairWearablesFlow: DashboardDriver.PairWearablesModal?
    @State private var showNextViewInFlow = false
    @State private var userChooseYes = true
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    private(set) var wearableId: String?
    
    var body: some View {
        if #available(iOS 17.0, *) {
            mainStack
            .navigationDestination(isPresented: $showNextViewInFlow) {
                if userChooseYes {
                    WearablesPlacedOnPatient(
                        pairWearablesFlow: $pairWearablesFlow,
                        wearableId: wearableId
                    )
                    .environmentObject(dashboardDriver)
                } else {
                    PlacingPatchInstruction(
                        pairWearablesFlow: $pairWearablesFlow,
                        wearableId: wearableId
                    )
                    .environmentObject(dashboardDriver)
                }
            }
        } else {
            mainStack
        }
    }

    @ViewBuilder
    var mainStack: some View {
        ZStack {
            if #unavailable(iOS 17.0) {
                NavigationLink(
                    destination: Group(
                        content: {
                            if userChooseYes {
                                WearablesPlacedOnPatient(
                                    pairWearablesFlow: $pairWearablesFlow,
                                    wearableId: wearableId)
                                .environmentObject(dashboardDriver)
                            } else {
                                PlacingPatchInstruction(
                                    pairWearablesFlow: $pairWearablesFlow,
                                    wearableId: wearableId)
                                .environmentObject(dashboardDriver)
                            }
                        }),
                    isActive: $showNextViewInFlow,
                    label: { EmptyView() }
                )
            }
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        Image(R.image.steps2Of3Percent10.name)
                            .resizable()
                            .frame(height: 8)
                        Spacer(minLength: 23)
                        Text(R.string.localizable.step2Of3())
                            .font(.custom("Avenir", size: 14))
                            .fontWeight(.light)
                            .foregroundColor(.charcoal3)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Button(action: {
                                self.presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(R.image.chevronLeft.name)
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 34, height: 34)
                                    .foregroundColor(.black)
                            }

                            Text(R.string.localizable.pairWearable())
                                .font(.custom("Avenir", size: 24))
                                .bold()
                                .foregroundColor(.charcoal3)

                            Spacer()

                            Button(action: {
                                pairWearablesFlow = nil
                            }) {
                                Image(R.image.cross.name)
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.charcoal3)
                            }
                            .hidden()
                        }

                        Text(R.string.localizable.isThereAPatch())
                            .font(.custom("Avenir", size: 24))
                            .fontWeight(.heavy)
                    }
                    Spacer()
                    VStack(alignment: .center) {
                        Image(R.image.patchApplied.name)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                    VStack(alignment: .center, spacing: 16) {
                        Button {
                            patientDriver.incrementPatchIfNeeded()
                            showNextViewInFlow.toggle()
                            userChooseYes = true
                        } label: {
                            Text(R.string.localizable.yes())
                                .padding(.horizontal, 159)
                        }
                        .altBtnIndigo()
                        Button {
                            patientDriver.handleNoPatchTapped()
                            self.showNextViewInFlow.toggle()
                            self.userChooseYes = false
                        } label: {
                            Text(R.string.localizable.no())
                                .padding(.horizontal, 159)
                                .foregroundColor(.aqua1)
                        }
                        .altBtnSecondaryBordered()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            VStack {
                Spacer()
                Text(DeviceConstants.getBuildInfoStr(facilityName: userDefaults.facilityName))
                    .textStyle(.overline, color: .silver)
                    .multilineTextAlignment(.center)
            }
        }
        .navigationBarHidden(true)
    }
}

struct PairingWearableStepTwo_Previews: PreviewProvider {
    static var previews: some View {
        PairingWearableStepTwo(pairWearablesFlow: .constant(nil),
                               wearableId: "ECFZU7CHZ0")
        .environmentObject(DashboardDriver())
        .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
