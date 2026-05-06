//
//  PlacingPatchInstruction.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 10/7/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

enum PlacingPatchInstructionStep {
    case openPackage
    case removeFilm
    case applyPatch
    case placeToHousing
    case closeHousing
    
    var label: String {
        switch self {
        case .openPackage:
            return R.string.localizable.openPackage()
        case .removeFilm:
            return R.string.localizable.removeFilm()
        case .applyPatch:
            return R.string.localizable.applyPatch()
        case .placeToHousing:
            return R.string.localizable.placeToHousing()
        case .closeHousing:
            return R.string.localizable.closeHousing()
        }
    }
    
    var image: String {
        switch self {
        case .openPackage:
            return R.image.openPackage.name
        case .removeFilm:
            return R.image.removeFilm.name
        case .applyPatch:
            return R.image.applyPatch.name
        case .placeToHousing:
            return R.image.placeToHousing.name
        case .closeHousing:
            return R.image.closeHousing.name
        }
    }
    
    var buttonLabel: String {
        switch self {
        case .openPackage:
            return R.string.localizable.continue()
        case .removeFilm:
            return R.string.localizable.doneContinue()
        case .applyPatch:
            return R.string.localizable.appliedContinue()
        case .placeToHousing:
            return R.string.localizable.insideContinue()
        case .closeHousing:
            return R.string.localizable.secureContinue()
        }
    }
}

struct PlacingPatchInstruction: View {
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
                    WearablesPlacedOnPatient(
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
                    destination: WearablesPlacedOnPatient(
                        pairWearablesFlow: $pairWearablesFlow,
                        wearableId: wearableId
                    )
                    .environmentObject(dashboardDriver),
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
                }
                VStack(alignment: .leading) {
                    HStack {
                        Button(action: {
                            if dashboardDriver.instructionStep.count != 1 {
                                dashboardDriver.instructionStep.removeLast()
                            } else {
                                self.presentationMode.wrappedValue.dismiss()
                            }
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

                    VStack {
                        Text(dashboardDriver.instructionStep.last?.label ?? "Unknown")
                            .font(.custom("Avenir", size: 24))
                            .fontWeight(.heavy)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        Image(dashboardDriver.instructionStep.last?.image ?? R.image.positionUnknown.name)
                            .resizable()
                            .conditionalModifier(
                                dashboardDriver.instructionStep.last == .openPackage ||
                                dashboardDriver.instructionStep.last == .removeFilm
                            ) {
                                $0.frame(width: 256, height: 256)
                            }
                            .conditionalModifier(
                                dashboardDriver.instructionStep.last == .applyPatch ||
                                dashboardDriver.instructionStep.last == .closeHousing
                            ) {
                                $0.frame(width: 218, height: 256)
                            }
                            .conditionalModifier(dashboardDriver.instructionStep.last == .placeToHousing) {
                                $0.frame(width: 190, height: 256)
                            }
                        Spacer()
                        Button {
                            switch dashboardDriver.instructionStep.last {
                            case .openPackage:
                                withAnimation {
                                    dashboardDriver.instructionStep.append(.removeFilm)
                                }
                            case .removeFilm:
                                withAnimation {
                                    dashboardDriver.instructionStep.append(.applyPatch)
                                }
                            case .applyPatch:
                                withAnimation {
                                    dashboardDriver.instructionStep.append(.placeToHousing)
                                }
                            case .placeToHousing:
                                withAnimation {
                                    dashboardDriver.instructionStep.append(.closeHousing)
                                }
                            case .closeHousing:
                                showNextViewInFlow = true
                            case .none:
                                return
                            }
                        } label: {
                            Text(dashboardDriver.instructionStep.last?.buttonLabel ?? "Unknown")
                                .frame(width: 343)
                        }
                        .altBtnIndigo()
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

struct PlacingPatchInstruction_Previews: PreviewProvider {
    static var previews: some View {
        PlacingPatchInstruction(pairWearablesFlow: .constant(nil),
                                wearableId: "ECFZU7CHZ0")
        .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
        .environmentObject(DashboardDriver())
    }
}
