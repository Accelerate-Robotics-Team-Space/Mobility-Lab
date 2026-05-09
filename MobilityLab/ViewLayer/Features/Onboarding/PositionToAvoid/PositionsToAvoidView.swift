//
//  PositionsToAvoidView.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/16/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

enum PatientProfileTurningProtocolSelection {
    case none
    case turnProtocol
    case complianceAngle
}

struct PositionsToAvoidView: View {
    @Injected(\.userDefaults) private var userDefaults

    @EnvironmentObject private var patientLandingDriver: PatientLandingDriver
    @ObservedObject var positionsToAvoidDriver: PositionsToAvoidDriver
    @Binding var patientFlow: PatientLandingDriver.ActiveModal?
    @Binding private var showView: Bool

    @State private var showNextViewInFlow: Bool = false
    @State private var showBotSheet: Bool = false
    @State private var selectedTurnString: String?
    @State private var selectedComplianceAngle: String?
    @State private var currentSelection = PatientProfileTurningProtocolSelection.none
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    // MARK: - Computed Variable
    private var goNextStr: String {
        if patientFlow == nil {
            return R.string.localizable.confirm()
        } else {
            return R.string.localizable.addPatient()
        }
    }

    // MARK: - Init
    init(showView: Binding<Bool>, flow: Binding<PatientLandingDriver.ActiveModal?> = .constant(nil)) {
        self.positionsToAvoidDriver = PositionsToAvoidDriver()
        self._patientFlow = flow
        self._showView = showView
        if let turnProtocol = userDefaults.turnProtocol {
            self._selectedTurnString = State(initialValue: turnProtocol.rawValue)
        }
        if let complianceAngle = userDefaults.complianceAngle {
            self._selectedComplianceAngle = State(initialValue: complianceAngle.readable)
        }
    }

    fileprivate init() {
        self.positionsToAvoidDriver = PositionsToAvoidDriver()
        self._patientFlow = .constant(nil)
        self._showView = .constant(true)
        if let turnProtocol = userDefaults.turnProtocol {
            self._selectedTurnString = State(initialValue: turnProtocol.rawValue)
        }
        if let complianceAngle = userDefaults.complianceAngle {
            self._selectedComplianceAngle = State(initialValue: complianceAngle.readable)
        }
    }

    // MARK: - Body
    var body: some View {
        if #available(iOS 17.0, *) {
            mainStack
                .navigationDestination(isPresented: $showNextViewInFlow) {
                    PatientEndingView(
                        patientLandingDriver: patientLandingDriver,
                        showView: $showNextViewInFlow,
                        flow: $patientFlow
                    )
                }
        } else {
            mainStack
        }
    }

    @ViewBuilder
    private var mainStack: some View {
        GeometryReader { geo in
            ZStack {
                VStack {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))

                navigationLink

                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        stepsView

                        VStack(alignment: .leading) {
                            HStack {
                                addPatientText
                                Spacer()
                                ALTExitButton {
                                    dismiss()
                                }
                                .frame(width: 18, height: 18)
                            }
                        }
                        positionsToAvoidText
                    }
                    .padding()

                    Spacer()

                    positionsToAvoidStack

                    if userDefaults.isComplianceEnabled || userDefaults.isTurnProtocolEnabled {
                        Spacer()
                            .frame(height: 40)
                        HStack {
                            if userDefaults.isTurnProtocolEnabled {
                                turnProtocolField
                            }
                            if userDefaults.isComplianceEnabled && userDefaults.isTurnProtocolEnabled {
                                Spacer()
                                    .frame(width: 16)
                            }
                            if userDefaults.isComplianceEnabled {
                                complianceDegreeField
                            }
                        }
                        .padding()
                    }

                    Spacer()
                        .frame(height: showBotSheet ? 200 : 40)

                    HStack(spacing: 70) {
                        backButton
                        Spacer()
                        goNextButton
                    }
                    .padding()
                    .padding(.bottom, geo.safeAreaInsets.bottom)
                }
                .background(background)

                bottomSheetView(geo)

                buildInfoView(geo)
            }
            .padding(.bottom, -geo.safeAreaInsets.bottom)
            .background(Color.white.opacity(0.1))
        }
        .presentContent(
            isPresented: $positionsToAvoidDriver.showAlert,
            tag: 31,
            content: { _ in
                alertView()
            }
        )
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private var stepsView: some View {
        HStack {
            Image(R.image.steps3Of4.name)
                .resizable()
                .frame(height: 8)
            Spacer(minLength: 23)
            Text(R.string.localizable.step3Of4())
                .font(.custom("Avenir", size: 14))
                .fontWeight(.light)
                .foregroundColor(.charcoal3)
        }
    }

    @ViewBuilder
    private var addPatientText: some View {
        Text(R.string.localizable.addAPatient())
            .font(.custom("Avenir", size: 24))
            .bold()
            .foregroundColor(.charcoal3)
    }

    @ViewBuilder
    private var positionsToAvoidText: some View {
        Text(R.string.localizable.positionToAvoid())
            .textStyle(.header3, color: .charcoal1)
    }

    @ViewBuilder
    private var positionsToAvoidStack: some View {
        VStack(spacing: 0) {
            ForEach(positionsToAvoidDriver.profile.positionsToAvoid) { flag in
                BindedRadioBtn(
                    .simpleImage(
                        title: flag.description,
                        image: flag.imageStr
                    ),
                    binding: $positionsToAvoidDriver.positionDict[flag]) { isOn in
                        positionsToAvoidDriver.positionDict.keys.forEach {
                            positionsToAvoidDriver.positionDict[$0] = false
                        }
                        positionsToAvoidDriver.positionDict[flag] = isOn
                    positionsToAvoidDriver.updateCache(positionToAvoid: flag, isOn: isOn)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var navigationLink: some View {
        if #available(iOS 17.0, *) {
            EmptyView()
        } else {
            NavigationLink(
                destination: PatientEndingView(
                    patientLandingDriver: patientLandingDriver,
                    showView: $showNextViewInFlow,
                    flow: $patientFlow
                ),
                isActive: $showNextViewInFlow,
                label: { EmptyView() }
            )
        }
    }

    @ViewBuilder
    private var turnProtocolField: some View {
        TriggerField(
            "Turn Protocol",
            placeholder: "Turn Protocol",
            selectedText: $selectedTurnString
        ) {
            currentSelection = .turnProtocol
            toggleBotSheet()
        }
    }

    @ViewBuilder
    private var complianceDegreeField: some View {
        TriggerField(
            "Effective Turn Angle",
            placeholder: "Effective Turn Angle",
            selectedText: .constant(userDefaults.complianceAngle!.readable)
        ) {
            currentSelection = .complianceAngle
            toggleBotSheet()
        }
    }

    @ViewBuilder
    private var backButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            Text(R.string.localizable.back())
                .padding(.horizontal, 24)
        })
        .altBtnSecondaryBordered()
    }

    @ViewBuilder
    private var goNextButton: some View {
        Button(action: {
            positionsToAvoidDriver.goNextBtnPress {
                showNextViewInFlow.toggle()
            }
        }, label: {
            Text(goNextStr)
                .frame(maxWidth: .infinity)
        })
        .altBtnIndigo()
    }

    @ViewBuilder
    private var background: some View {
        Rectangle()
            .fill(Color.white)
            .cornerRadius(24, corners: [.topLeft, .topRight])
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 2,
                x: 0,
                y: 0
            )
    }

    @ViewBuilder
    private func bottomSheetView(_ geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            BottomSheetView(isOpen: $showBotSheet, maxHeight: geo.size.height * 0.45) {
                if currentSelection == .turnProtocol {
                    ProfileTurnProtocolSelectionView(showBotSheet: $showBotSheet,
                                                     selectedString: $selectedTurnString)
                } else if currentSelection == .complianceAngle {
                    ProfileComplianceAngleSelectionView(showBotSheet: $showBotSheet,
                                                        selectedString: $selectedComplianceAngle)
                }
            }
            .padding(.bottom, geo.safeAreaInsets.bottom)
        }
    }

    @ViewBuilder
    private func buildInfoView(_ geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            Text(DeviceConstants.getBuildInfoStr(facilityName: userDefaults.facilityName))
                .textStyle(.overline, color: .silver)
                .multilineTextAlignment(.center)
                .padding(.bottom, geo.safeAreaInsets.bottom)
        }
    }

    private func toggleBotSheet() {
        withAnimation {
            showBotSheet.toggle()
        }
    }
}

// MARK: - Private
private extension PositionsToAvoidView {
    func dismiss() {
        if patientFlow != nil {
            patientFlow = nil
            positionsToAvoidDriver.resetCache()
        } else {
            showView = false
        }
    }

    @ViewBuilder
    func alertView() -> some View {
        CardViewWithButton(
            title: R.string.localizable.patientError(),
            msg: positionsToAvoidDriver.alertMsg,
            buttonTitle: R.string.localizable.ok()
        ) {
            positionsToAvoidDriver.showAlert.toggle()
        }
        .frame(maxWidth: 280)
    }
}

// MARK: - Preview
struct PositionsToAvoidView_Previews: PreviewProvider {
    static var previews: some View {
        PositionsToAvoidView()
            .environmentObject(PatientLandingDriver())
    }
}
