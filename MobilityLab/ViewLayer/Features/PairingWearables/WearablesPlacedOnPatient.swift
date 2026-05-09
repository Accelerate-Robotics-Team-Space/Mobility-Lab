//
//  WearablesPlacedOnPatient.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 10/7/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct WearablesPlacedOnPatient: View {
    @EnvironmentObject var dashboardDriver: DashboardDriver
    @Binding var pairWearablesFlow: DashboardDriver.PairWearablesModal?
    @State private var currentPlacement: WearableLocation?
    @State private var showNextViewInFlow: Bool = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Injected(\.userDefaults) private var userDefaults

    private(set) var wearableId: String?

    var body: some View {
        if #available(iOS 17.0, *) {
            ZStack {
                vStack
                deviceInfoView
            }
            .navigationDestination(isPresented: $showNextViewInFlow) {
                CalibrateWearable(
                    pairWearablesFlow: $pairWearablesFlow,
                    wearableId: wearableId
                )
                .environmentObject(dashboardDriver)
            }
            .navigationBarHidden(true)
            .alert(isPresented: $dashboardDriver.showDataFeedAlert, content: { dataFeedAlert })
        } else {
            ZStack {
                navigationLink
                vStack
                deviceInfoView
            }
            .navigationBarHidden(true)
            .alert(isPresented: $dashboardDriver.showDataFeedAlert, content: { dataFeedAlert })
        }
    }

    @ViewBuilder
    private var vStack: some View {
        VStack {
            stepsText
            VStack(alignment: .leading) {
                navigationStack

                whereIsText

                Spacer()

                bodyButtonsStack

                rotateButton

                Spacer()
            }

            Spacer()

            continueButton
        }
        .padding()
    }

    private var dataFeedAlert: Alert {
        Alert(
            title: Text(R.string.localizable.dataFeedErr()),
            message: Text(R.string.localizable.dataFeedErrMsg()),
            dismissButton: .default(
                R.string.localizable.ok.text,
                action: {
                    dashboardDriver.rejectRequest()
                    pairWearablesFlow = nil
                }
            )
        )
    }

    @ViewBuilder
    private var navigationLink: some View {
        if #available(iOS 17.0, *) {
            EmptyView()
        } else {
            NavigationLink(
                destination: CalibrateWearable(
                    pairWearablesFlow: $pairWearablesFlow,
                    wearableId: wearableId
                )
                .environmentObject(dashboardDriver),
                isActive: $showNextViewInFlow,
                label: { EmptyView() }
            )
        }
    }

    @ViewBuilder
    private var navigationStack: some View {
        HStack {
            chevronButton

            pairWearableText

            Spacer()

            crossButtonView
        }
    }

    @ViewBuilder
    private var stepsText: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(R.image.steps2Of3Percent20.name)
                    .resizable()
                    .frame(height: 8)
                Spacer(minLength: 23)
                Text(R.string.localizable.step2Of3())
                    .font(.custom("Avenir", size: 14))
                    .fontWeight(.light)
                    .foregroundColor(.charcoal3)
            }
        }
    }

    @ViewBuilder
    private var chevronButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(R.image.chevronLeft.name)
                .renderingMode(.template)
                .resizable()
                .frame(width: 34, height: 34)
                .foregroundColor(.black)
        }
    }

    @ViewBuilder
    private var pairWearableText: some View {
        Text(R.string.localizable.pairWearable())
            .font(.custom("Avenir", size: 24))
            .bold()
            .foregroundColor(.charcoal3)
    }

    @ViewBuilder
    private var crossButtonView: some View {
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

    @ViewBuilder
    private var whereIsText: some View {
        Text(R.string.localizable.whereIsWearable())
            .font(.custom("Avenir", size: 24))
            .fontWeight(.heavy)
    }

    @ViewBuilder
    private var bodyButtonsStack: some View {
        VStack(alignment: .center, spacing: 25) {
            ZStack(alignment: .center) {
                VStack {
                    HStack(alignment: .top, spacing: 0) {
                        rightArmButton
                        VStack(spacing: 0) {
                            chestButton
                            HStack(spacing: 4) {
                                rightLegButton
                                leftLegButton
                            }
                        }
                        leftArmButton
                    }
                }
                if dashboardDriver.isLoading {
                    progressView
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var rightArmButton: some View {
        Button {
            currentPlacement = .rightArm
        } label: {
            ZStack {
                Image(currentPlacement == .rightArm ?
                      R.image.rightArmFilled.name : R.image.rightArmUnfilled.name)
            }
        }
        .disabled(true)
    }

    @ViewBuilder
    private var chestButton: some View {
        Button {
            currentPlacement = .chest
        } label: {
            ZStack {
                Image(currentPlacement == .chest ? R.image.chestFilled.name : R.image.chestUnfilled.name)
            }
        }
    }

    @ViewBuilder
    private var rightLegButton: some View {
        Button {
            currentPlacement = .rightLeg
        } label: {
            ZStack {
                Image(currentPlacement == .rightLeg ? R.image.rightLegFilled.name : R.image.rightLegUnfilled.name)
            }
        }
        .offset(y: -8)
        .disabled(true)
    }

    @ViewBuilder
    private var leftLegButton: some View {
        Button {
            currentPlacement = .leftLeg
        } label: {
            ZStack {
                Image(currentPlacement == .leftLeg ? R.image.leftLegFilled.name : R.image.leftLegUnfilled.name)
            }
        }
        .offset(y: -8)
        .disabled(true)
    }

    @ViewBuilder
    private var leftArmButton: some View {
        Button {
            currentPlacement = .leftArm
        } label: {
            ZStack {
                Image(currentPlacement == .leftArm ? R.image.leftArmFilled.name : R.image.leftArmUnfilled.name)
            }
        }
        .disabled(true)
    }

    @ViewBuilder
    private var progressView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .aqua))
            .scaleEffect(2, anchor: .center)
    }

    @ViewBuilder
    private var rotateButton: some View {
        Button {
            // Rotate Clicked
        } label: {
            Image(R.image.rotate.name)
        }
        .frame(maxWidth: .infinity)
        .disabled(true)
    }

    @ViewBuilder
    private var continueButton: some View {
        Button {
            guard let currentPlacement = currentPlacement else { return }
            dashboardDriver.answerRequest(true, location: currentPlacement) { answer in
                if answer {
                    showNextViewInFlow = true
                } else {
                    // show alert
                }
            }
        } label: {
            Text(R.string.localizable.continue())
                .padding(.horizontal, 137)
        }
        .conditionalModifier(currentPlacement == nil) {
            $0.altBtnIndigoDisabled()
        }
        .conditionalModifier(currentPlacement != nil) {
            $0.altBtnIndigo()
        }
    }

    @ViewBuilder
    private var deviceInfoView: some View {
        VStack {
            Spacer()
            Text(DeviceConstants.getBuildInfoStr(facilityName: userDefaults.facilityName))
                .textStyle(.overline, color: .silver)
                .multilineTextAlignment(.center)
        }
    }
}

struct WearablesPlacedOnPatient_Previews: PreviewProvider {
    static var previews: some View {
        WearablesPlacedOnPatient(pairWearablesFlow: .constant(nil),
                                 wearableId: "ECFZU7CHZ0")
            .environmentObject(DashboardDriver())
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
