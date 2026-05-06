//
//  PairingWearableStepOne.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 10/6/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct PairingWearableStepOne: View {
    @EnvironmentObject var dashboardDriver: DashboardDriver
    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    @Binding var pairWearablesFlow: DashboardDriver.PairWearablesModal?
    @Binding var wearableId: String?
    @Injected(\.userDefaults) private var userDefaults
    @State private var showNextViewInFlow = false
    
    var body: some View {
        if #available(iOS 17.0, *) {
            mainStack
                .navigationDestination(isPresented: $showNextViewInFlow) {
                    PairingWearableStepTwo(
                        pairWearablesFlow: $pairWearablesFlow,
                        wearableId: wearableId
                    )
                    .environmentObject(dashboardDriver)
                    .environmentObject(patientMonitorDriver)
                }
        } else {
            mainStack
        }
    }
    
    // MARK: - Init
    init(pairWearablesFlow: Binding<DashboardDriver.PairWearablesModal?>, request: DataFeedRequest?) {
        self._pairWearablesFlow = pairWearablesFlow
        self._wearableId = .constant(request?.wearableId.formattedId())
    }

    @ViewBuilder
    var mainStack: some View {
        ZStack(alignment: .bottom) {
            if #unavailable(iOS 17.0) {
                NavigationLink(
                    destination: PairingWearableStepTwo(
                        pairWearablesFlow: $pairWearablesFlow,
                        wearableId: wearableId
                    )
                    .environmentObject(dashboardDriver)
                    .environmentObject(patientMonitorDriver),
                    isActive: $showNextViewInFlow,
                    label: { EmptyView() }
                )
            }
            VStack(spacing: 46) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(R.image.steps1Of3.name)
                            .resizable()
                            .frame(height: 8)
                        Spacer(minLength: 23)
                        Text(R.string.localizable.step1Of3())
                            .font(.custom("Avenir", size: 14))
                            .fontWeight(.light)
                            .foregroundColor(.charcoal3)
                    }

                    VStack(alignment: .leading) {
                        HStack {
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

                        Text(R.string.localizable.wearableTryingToConnect())
                            .font(.custom("Avenir", size: 24))
                            .fontWeight(.heavy)
                    }
                }

                VStack(alignment: .center, spacing: 16) {
                    Image(R.image.watch.name)
                        .resizable()
                        .scaledToFit()
                    Text(wearableId ?? "?")
                        .font(.custom("SF Compact Text", size: 16))
                        .bold()
                        .foregroundColor(.aqua1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 1000)
                                .stroke(Color.aqua1, lineWidth: 1)
                        )
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .center, spacing: 16) {
                    Button {
                        dashboardDriver.userDidSelectPairing()
                        if !dashboardDriver.swappingInProgress {
                            showNextViewInFlow = true
                        } else {
                            dashboardDriver.answerRequest(true, location: dashboardDriver.tmpLocation) { answer in
                                if answer {
                                    dashboardDriver.swappingInProgress = false
                                    dashboardDriver.resetSwapping()
                                    pairWearablesFlow = nil
                                }
                            }
                        }
                    } label: {
                        Text(R.string.localizable.pair())
                            .padding(.horizontal, 157)
                    }
                    .altBtnIndigo()
                    Button {
                        dashboardDriver.rejectRequest()
                        pairWearablesFlow = nil
                    } label: {
                        Text(R.string.localizable.reject())
                            .padding(.horizontal, 148)
                    }
                    .altBtnWhiteRedBorder()
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            Text(DeviceConstants.getBuildInfoStr(facilityName: userDefaults.facilityName))
                .textStyle(.overline, color: .silver)
                .multilineTextAlignment(.center)
        }
        .navigationBarHidden(true)
        .interactiveDismissDisabled()
    }
}

struct PairingWearableStepOne_Previews: PreviewProvider {
    static var previews: some View {
        PairingWearableStepOne(pairWearablesFlow: .constant(nil),
                               request: DataFeedRequest.previewRequest)
        .environmentObject(DashboardDriver())
        .environmentObject(PatientMonitorDriver())
        .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
