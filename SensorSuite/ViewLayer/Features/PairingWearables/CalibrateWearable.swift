//
//  CalibrateWearable.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 10/12/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct CalibrateWearable: View {
    @EnvironmentObject var dashboardDriver: DashboardDriver
    @Binding var pairWearablesFlow: DashboardDriver.PairWearablesModal?
    @State private var showNextViewInFlow = false
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    @Injected(\.userDefaults) private var userDefaults
    private(set) var wearableId: String?
    
    var body: some View {
        if #available(iOS 17.0, *) {
            mainStack
                .navigationDestination(isPresented: $showNextViewInFlow) {
                    CalibrateInstructions(
                        pairWearablesFlow: $pairWearablesFlow,
                        wearableId: wearableId
                    )
                    .environmentObject(dashboardDriver)
                }
        } else {
            mainStack
        }
    }

    @ViewBuilder
    private var mainStack: some View {
        ZStack {
            if #unavailable(iOS 17.0) {
                NavigationLink(
                    destination: CalibrateInstructions(
                        pairWearablesFlow: $pairWearablesFlow,
                        wearableId: wearableId
                    )
                    .environmentObject(dashboardDriver),
                    isActive: $showNextViewInFlow,
                    label: { EmptyView() }
                )
            }

            VStack(spacing: 46) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(R.image.steps2Of3Percent50.name)
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

                        Text(R.string.localizable.calibrateWearable())
                            .font(.custom("Avenir", size: 24))
                            .fontWeight(.heavy)
                    }
                }

                VStack(alignment: .center, spacing: 16) {
                    ZStack {
                        Image(R.image.watch.name)
                            .resizable()
                            .scaledToFit()
                        Image(R.image.wedge.name)
                    }
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
                Spacer()
                VStack(alignment: .center, spacing: 16) {
                    Button {
                        showNextViewInFlow = true
                    } label: {
                        Text(R.string.localizable.continue())
                            .padding(.horizontal, 137)
                    }
                    .altBtnIndigo()
                }
                .frame(maxWidth: .infinity)
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

struct CalibrateWearable_Previews: PreviewProvider {
    static var previews: some View {
        CalibrateWearable(pairWearablesFlow: .constant(nil),
                          wearableId: "ECFZU7CHZ0")
//            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
            .environmentObject(DashboardDriver())
    }
}
