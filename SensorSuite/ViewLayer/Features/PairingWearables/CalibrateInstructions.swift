//
//  CalibrateInstructions.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 10/12/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

enum CalibrateInstructionStep {
    case ensurePatientIsOnBack
    case ensureBedIsFlat
    
    var image: String {
        switch self {
        case .ensurePatientIsOnBack:
            return R.image.steps2Of3Percent75.name
        case .ensureBedIsFlat:
            return R.image.steps2Of3.name
        }
    }
    
    var label: String {
        switch self {
        case .ensurePatientIsOnBack:
            return R.string.localizable.ensurePatientIsOnBack()
        case .ensureBedIsFlat:
            return R.string.localizable.isTheBedFlat()
        }
    }
    
    var label2: String {
        switch self {
        case .ensurePatientIsOnBack:
            return R.string.localizable.patientOnBack()
        case .ensureBedIsFlat:
            return R.string.localizable.bedIsFlat()
        }
    }
    
    var padding: CGFloat {
        switch self {
        case .ensurePatientIsOnBack:
            return 87
        case .ensureBedIsFlat:
            return 50
        }
    }
}

struct CalibrateInstructions: View {
    @EnvironmentObject var dashboardDriver: DashboardDriver
    @Binding var pairWearablesFlow: DashboardDriver.PairWearablesModal?
    @State private var currentStep = CalibrateInstructionStep.ensurePatientIsOnBack
    @State private var showNextViewInFlow = false
    @State private var userChooseContinue = true
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>
    @Injected(\.userDefaults) private var userDefaults

    private(set) var wearableId: String?
    
    var body: some View {
        if #available(iOS 17.0, *) {
            mainStack
                .navigationDestination(isPresented: $showNextViewInFlow) {
                    if userChooseContinue {
                        CalibrateSequence(
                            pairWearablesFlow: $pairWearablesFlow,
                            wearableId: wearableId
                        )
                        .environmentObject(dashboardDriver)
                    } else {
                        ManualCalibration(
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
    private var mainStack: some View {
        ZStack {
            if #unavailable(iOS 17.0) {
                NavigationLink(
                    destination:
                        userChooseContinue
                    ?
                    AnyView(
                        CalibrateSequence(
                            pairWearablesFlow: $pairWearablesFlow,
                            wearableId: wearableId
                        )
                        .environmentObject(dashboardDriver)
                    )
                    :
                        AnyView(
                            ManualCalibration(
                                pairWearablesFlow: $pairWearablesFlow,
                                wearableId: wearableId
                            )
                            .environmentObject(dashboardDriver)
                        ),
                    isActive: $showNextViewInFlow,
                    label: { EmptyView() }
                )
            }
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        Image(currentStep.image)
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
                                if currentStep == .ensureBedIsFlat {
                                    currentStep = .ensurePatientIsOnBack
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

                        Text(currentStep.label)
                            .font(.custom("Avenir", size: 24))
                            .fontWeight(.heavy)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .center) {
                    if currentStep == .ensurePatientIsOnBack {
                        Spacer()
                        Image(R.image.positionSupine1.name)
                        Spacer()
                    } else if currentStep == .ensureBedIsFlat {
                        Image(R.image.pairWearablesBackground.name)
                    }
                }

                Spacer()

                VStack(alignment: .center, spacing: 16) {
                    if currentStep == .ensurePatientIsOnBack {
                        Button {
                            showNextViewInFlow = true
                            userChooseContinue = false
                        } label: {
                            Text(R.string.localizable.iCantDoThat())
                                .padding(.horizontal, 123)
                        }
                        .altBtnIndigo()
                    }
                    Button {
                        if currentStep == .ensurePatientIsOnBack {
                            withAnimation {
                                currentStep = .ensureBedIsFlat
                            }
                        } else if currentStep == .ensureBedIsFlat {
                            showNextViewInFlow = true
                            userChooseContinue = true
                        }
                    } label: {
                        Text(currentStep.label2)
                            .padding(.horizontal, currentStep.padding)
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

struct CalibrateInstructions_Previews: PreviewProvider {
    static var previews: some View {
        CalibrateInstructions(pairWearablesFlow: .constant(nil),
                              wearableId: "ECFZU7CHZ0")
//            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
