//
//  PatientLocationView.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/16/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

enum PatientLocationSelection {
    case unit
    case room
}

struct PatientLocationView: View {
    @ObservedObject var driver: PatientLocationDriver
    @ObservedObject private var patientLandingDriver: PatientLandingDriver
    @Binding var patientFlow: PatientLandingDriver.ActiveModal?
    @Binding var patientProfileFlow: ProfileDriver.ProfileActiveModal?
    @Binding var showView: Bool
    
    @State private var currentSelection = PatientLocationSelection.unit
    @State private var showNextViewInFlow: Bool = false
    @State private var showBotSheet: Bool = false
    @State private var showAlert: Bool = false
    @State private var hasSternumSkinBroken: Bool = false

    private var locationAlert: Alert {
        Alert(title: R.string.localizable.unitHasNoRooms.text)
    }
    
    private var goNextStr: String {
        if patientFlow == nil {
            return R.string.localizable.continue()
        } else {
            return R.string.localizable.continue()
        }
    }

    // MARK: - Init
    init(patientLandingDriver: PatientLandingDriver, patientFlow: Binding<PatientLandingDriver.ActiveModal?>) {
        self.driver = PatientLocationDriver()
        self.patientLandingDriver = patientLandingDriver
        self._patientFlow = patientFlow
        self._patientProfileFlow = .constant(nil)
        self._showView = .constant(true)
    }

    init(flow: Binding<ProfileDriver.ProfileActiveModal?>) {
        self.driver = PatientLocationDriver()
        self.patientLandingDriver = PatientLandingDriver()
        self._patientFlow = .constant(nil)
        self._patientProfileFlow = flow
        self._showView = .constant(true)
    }

    init(showView: Binding<Bool>) {
        self.driver = PatientLocationDriver()
        self.patientLandingDriver = PatientLandingDriver()
        self._patientFlow = .constant(nil)
        self._patientProfileFlow = .constant(nil)
        self._showView = showView
    }

    fileprivate init() {
        self.driver = PatientLocationDriver()
        self.patientLandingDriver = PatientLandingDriver()
        self._patientFlow = .constant(nil)
        self._patientProfileFlow = .constant(nil)
        self._showView = .constant(true)
    }

    // MARK: - body
    var body: some View {
        GeometryReader { geo in
            if #available(iOS 17.0, *) {
                NavigationStack {
                    zStack(geo)
                }
            } else {
                NavigationView {
                    zStack(geo)
                }
            }
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    func zStack(_ geo: GeometryProxy) -> some View {
        if #available(iOS 17.0, *) {
            ZStack(alignment: .bottom) {
                zStackContents(geo)
            }
            .padding(.bottom, -geo.safeAreaInsets.bottom)
            .background(Color.white.opacity(0.1))
            .navigationDestination(isPresented: $showNextViewInFlow) {
                PatientProfileView(
                    patientLandingDriver: patientLandingDriver,
                    showView: $showNextViewInFlow,
                    flow: $patientFlow,
                    hasSternumSkinBroken: hasSternumSkinBroken
                )
            }
        } else {
            ZStack(alignment: .bottom) {
                zStackContents(geo)
            }
            .padding(.bottom, -geo.safeAreaInsets.bottom)
            .background(Color.white.opacity(0.1))
        }
    }

    @ViewBuilder
    func zStackContents(_ geo: GeometryProxy) -> some View {
        if patientProfileFlow == nil {
            VStack {}
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
        }
        if #unavailable(iOS 17.0) {
            navigationLink
        }
        mainStack(geo)

        if showBotSheet {
            gradientView
        }

        if !driver.unitInfo.isEmpty {
            bottomSheetView(geo)
        }

        if driver.showContraindications {
            contraindicationsView
        }
    }

    @ViewBuilder
    private func mainStack(_ geo: GeometryProxy) -> some View {
        VStack {
            VStack(alignment: .leading) {
                stepView
                patientLocationStack
            }

            Spacer()

            VStack {
                unitField

                roomBedField
            }

            VStack { }
                .frame(height: 16)

            if patientProfileFlow == nil {
                goNextButton
                    .padding(.bottom, geo.safeAreaInsets.bottom)
            } else {
                VStack(spacing: 16) {
                    patientProfileFlowButton
                }
                .padding(.bottom, geo.safeAreaInsets.bottom)
            }
        }
        .padding(.all, 16)
        .background(backgroundView)
        .alert(isPresented: $showAlert, content: { locationAlert })
        .onTapGesture(count: 1) {
            guard showBotSheet == true else { return }
            toggleBotSheet()
        }
        .allowsHitTesting(!driver.showContraindications)
    }

    @ViewBuilder
    private var stepView: some View {
        if patientProfileFlow == nil {
            HStack {
                Image(R.image.steps1Of4.name)
                    .resizable()
                    .frame(height: 8)
                Spacer(minLength: 23)
                Text(R.string.localizable.step1Of4())
                    .font(.custom("Avenir", size: 14))
                    .fontWeight(.light)
                    .foregroundColor(.charcoal3)
            }
        }
    }

    @ViewBuilder
    private var navigationLink: some View {
        if #available(iOS 17.0, *) {
            EmptyView()
        } else {
            NavigationLink(
                destination: PatientProfileView(
                    patientLandingDriver: patientLandingDriver,
                    showView: $showNextViewInFlow,
                    flow: $patientFlow,
                    hasSternumSkinBroken: hasSternumSkinBroken
                ),
                isActive: $showNextViewInFlow,
                label: { EmptyView() }
            )
        }
    }

    @ViewBuilder
    private var patientLocationStack: some View {
        VStack(alignment: .leading) {
            HStack {
                editLocationView

                Spacer()

                ALTExitButton {
                    dismiss()
                }
                .frame(width: 18, height: 18)
            }

            whereIsPatientLabel
        }
    }

    @ViewBuilder
    private var editLocationView: some View {
        if patientFlow != nil {
            Text(R.string.localizable.addAPatient())
                .font(.custom("Avenir", size: 24))
                .bold()
                .foregroundColor(.charcoal3)
        } else if patientProfileFlow != nil {
            Text(R.string.localizable.editPatientLocation())
                .font(.custom("Avenir-Heavy", size: 24))
                .foregroundColor(.charcoal3)
        }
    }

    @ViewBuilder
    private var whereIsPatientLabel: some View {
        if patientFlow != nil {
            Text(R.string.localizable.whereIsPatient())
                .textStyle(.header3, color: .charcoal1)
        } else if patientProfileFlow != nil {
            VStack {
                Text(R.string.localizable.wherePatientLocated())
                    .textStyle(.header3, color: .charcoal1)
                    .multilineTextAlignment(.leading)
            }
            .padding(.trailing, 37)
        }
    }

    @ViewBuilder
    private var unitField: some View {
        TriggerField(
            R.string.localizable.unit(),
            placeholder: R.string.localizable.selectPatientUnit(),
            selectedText: $driver.selectedUnitStr
        ) {
            currentSelection = .unit
            toggleBotSheet()
        }
    }

    @ViewBuilder
    private var roomBedField: some View {
        TriggerField(
            R.string.localizable.roomBed(),
            placeholder: R.string.localizable.selectPatientRoom(),
            selectedText: $driver.selectedRoomBedStr
        ) {
            currentSelection = .room
            if !driver.roomBedItems.isEmpty {
                toggleBotSheet()
            }
        }
        .disabled(driver.isRoomBedFieldDisabled)
    }

    @ViewBuilder
    private var goNextButton: some View {
        Button {
            driver.goNextBtnPress {
                if patientFlow == nil {
                    showView.toggle()
                } else {
                    showNextViewInFlow.toggle()
                }
            }
        } label: {
            Text(goNextStr)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(
            (!driver.canGoNext || driver.showContraindications)
                ? ALTButtonStyle.altBtnIndigoDisabled()
                : ALTButtonStyle()
        )
        .disabled(!driver.canGoNext || driver.showContraindications)
    }

    @ViewBuilder
    private var patientProfileFlowButton: some View {
        Button(action: {
            driver.goNextBtnPress {
                if patientProfileFlow != nil {
                    patientProfileFlow = nil
                } else {
                    showNextViewInFlow.toggle()
                }
            }
        }, label: {
            Text(R.string.localizable.save())
                .frame(maxWidth: .infinity)
        })
        .altBtnIndigo()
        Button(action: {
            patientProfileFlow = nil
        }, label: {
            Text(R.string.localizable.cancel())
                .frame(maxWidth: .infinity)
        })
        .altBtnIndigo()
    }

    @ViewBuilder
    private var backgroundView: some View {
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
    private var gradientView: some View {
        VStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        .faintingLight.opacity(0),
                        .faintingLight.opacity(0.2),
                    ]
                ),
                startPoint: .top,
                endPoint: .bottom)
        }
        .padding(.top, 200)
    }

    @ViewBuilder
    private func bottomSheetView(_ geo: GeometryProxy) -> some View {
        BottomSheetView(
            isOpen: $showBotSheet,
            maxHeight: geo.size.height * 0.45
        ) {
            switch currentSelection {
            case .unit:
                UnitSheetView(
                    driver: driver,
                    showBotSheet: $showBotSheet,
                    showAlert: $showAlert
                )
                .padding(.bottom, geo.safeAreaInsets.bottom)
            case .room:
                RoomBedSheetView(
                    driver: driver,
                    showBotSheet: $showBotSheet
                )
                .padding(.bottom, geo.safeAreaInsets.bottom)
            }
        }
    }

    @ViewBuilder
    private var contraindicationsView: some View {
        VStack {
            Spacer()
            PopupAlert(
                title: "Contraindications",
                msg: "Before we begin",
                image: nil,
                popupBtns: .default(
                    primaryBtn: .init(labelStr: "Submit", cta: {
                        driver.showContraindications = false
                    }),
                    secondaryBtn: .init(labelStr: "Dismiss", cta: {
                        withAnimation(.easeInOut(duration: 1)) {
                            driver.showContraindications = false
                            dismiss()
                        }
                    })
                ),
                popupExit: .default(cta: {
                    withAnimation(.easeInOut(duration: 1)) {
                        driver.showContraindications = false
                        dismiss()
                    }
                }),
                contraindications: true,
                hasBrokenSkin: $hasSternumSkinBroken
            )
            Spacer()
        }
    }
}

// MARK: - Private
private extension PatientLocationView {
    func toggleBotSheet() {
        withAnimation {
            showBotSheet.toggle()
        }
    }
    
    func dismiss() {
        if patientFlow != nil {
            patientFlow = nil
        } else if patientProfileFlow != nil {
            patientProfileFlow = nil
        } else {
            showView = false
        }
    }
}

// MARK: - Preview
struct PatientLocationView_Previews: PreviewProvider {
    static var previews: some View {
        PatientLocationView()
//            .previewDevice((PreviewDevice(rawValue: "iPhone 8 Plus")))
    }
}
