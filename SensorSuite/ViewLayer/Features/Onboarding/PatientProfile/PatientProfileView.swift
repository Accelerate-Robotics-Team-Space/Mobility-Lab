//
//  PatientProfileView.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/16/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

enum PatientProfileSelection {
    case height
    case weight
    case sex
    case bodyType
}

struct PatientProfileView: View {
    @ObservedObject var driver: PatientProfileDriver
    @ObservedObject var patientLandingDriver: PatientLandingDriver
    @Binding var patientFlow: PatientLandingDriver.ActiveModal?
    @Binding var patientProfileFlow: ProfileDriver.ProfileActiveModal?
    @Binding var showView: Bool
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>
    @Injected(\.userDefaults) private var userDefaults

    @State private var currentSelection = PatientProfileSelection.height
    @State private var showNextViewInFlow: Bool = false
    @State private var showBotSheet: Bool = false
    @State private var showError: Bool = false
    
    private var goNextStr: String {
        if patientFlow == nil {
            return R.string.localizable.confirm()
        } else {
            return R.string.localizable.continue()
        }
    }

    // MARK: - Init
    init(patientLandingDriver: PatientLandingDriver, showView: Binding<Bool>, flow: Binding<PatientLandingDriver.ActiveModal?> = .constant(nil),
         hasSternumSkinBroken: Bool) {
        self.driver = PatientProfileDriver()
        self.patientLandingDriver = patientLandingDriver
        self._patientFlow = flow
        self._patientProfileFlow = .constant(nil)
        self._showView = showView
        self.driver.hasSternumSkinBroken = hasSternumSkinBroken
    }

    init(flow: Binding<ProfileDriver.ProfileActiveModal?>) {
        self.driver = PatientProfileDriver()
        self.patientLandingDriver = PatientLandingDriver()
        self._patientFlow = .constant(nil)
        self._patientProfileFlow = flow
        self._showView = .constant(true)
    }

    fileprivate init() {
        self.driver = PatientProfileDriver()
        self.patientLandingDriver = PatientLandingDriver()
        self._patientFlow = .constant(nil)
        self._patientProfileFlow = .constant(nil)
        self._showView = .constant(true)
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack {
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
                
                bottomSheet(geo)

                VStack {
                    Spacer()
                    deviceInfoText
                }
                .padding(.bottom, geo.safeAreaInsets.bottom)
            }
            .padding(.bottom, -geo.safeAreaInsets.bottom)
            .background(Color.white.opacity(0.1))
            .alert(isPresented: $driver.showInvalidPatientAlert) {
                alert
            }
        }
        .navigationDestination(isPresented: $showNextViewInFlow) {
            PositionsToAvoidView(
                showView: $showNextViewInFlow,
                flow: $patientFlow
            )
            .environmentObject(patientLandingDriver)
        }
        .navigationBarHidden(true)
        .onTapGesture {
            self.dismissKeyboard()
        }
    }
}

// MARK: - Private
private extension PatientProfileView {
    @ViewBuilder
    func mainStack(_ geo: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                if patientProfileFlow == nil {
                    stepText
                }

                VStack(alignment: .leading) {
                    HStack {
                        if patientFlow != nil {
                            addPatientText
                        } else if patientProfileFlow != nil {
                            editDetailsText
                        }
                        Spacer()
                        ALTExitButton {
                            dismiss()
                        }
                        .frame(width: 18, height: 18)
                    }
                }
                if patientFlow != nil {
                    getPatientDetailsText
                } else if patientProfileFlow != nil {
                    whatPatientText
                }
            }

            Spacer()

            VStack {
                HStack(spacing: 16) {
                    heightField
                    weightField
                    bmiField
                }

                sexField
            }

            VStack { }
                .frame(height: 16)

            if patientProfileFlow == nil {
                HStack(spacing: 70) {
                    backButton
                    Spacer()
                    goNextButton
                }
                .padding(.bottom, geo.safeAreaInsets.bottom)
            } else {
                VStack(spacing: 16) {
                    saveButton
                    cancelButton
                }
                .padding(.bottom, geo.safeAreaInsets.bottom)
            }
        }
        .padding()
        .background(backgroundView)
    }

    @ViewBuilder
    var navigationLink: some View {
        if #available(iOS 17.0, *) {
            EmptyView()
        } else {
            NavigationLink(
                destination: PositionsToAvoidView(
                    showView: $showNextViewInFlow,
                    flow: $patientFlow
                )
                .environmentObject(patientLandingDriver),
                isActive: $showNextViewInFlow,
                label: { EmptyView() }
            )
        }
    }

    @ViewBuilder
    var stepText: some View {
        HStack {
            Image(R.image.steps2Of4.name)
                .resizable()
                .frame(height: 8)
            Spacer(minLength: 23)
            Text(R.string.localizable.step2Of4())
                .font(.custom("Avenir", size: 14))
                .fontWeight(.light)
                .foregroundColor(.charcoal3)
        }
    }

    @ViewBuilder
    var addPatientText: some View {
        Text(R.string.localizable.addAPatient())
            .font(.custom("Avenir", size: 24))
            .bold()
            .foregroundColor(.charcoal3)
    }

    @ViewBuilder
    var editDetailsText: some View {
        Text(R.string.localizable.editDetails())
            .font(.custom("Avenir-Heavy", size: 24))
            .foregroundColor(.charcoal3)
    }

    @ViewBuilder
    var getPatientDetailsText: some View {
        Text(R.string.localizable.getPatientDetail())
            .textStyle(.header3, color: .charcoal1)
    }

    @ViewBuilder
    var whatPatientText: some View {
        VStack {
            Text(R.string.localizable.whatPatientDetails())
                .textStyle(.header3, color: .charcoal1)
                .multilineTextAlignment(.leading)
        }
        .padding(.trailing, 24)
    }

    @ViewBuilder
    var heightField: some View {
        InputField(R.string.localizable.height(),
                   placeholder: "Enter",
                   inputTxt: $driver.selectedHeight,
                   requirement: $driver.heightUnit,
                   charCount: 3)
        .padding(.bottom, 18)
        .onChange(of: driver.heightUnit) { newValue in
            if newValue == .inches {
                driver.weightUnit = .pounds
                driver.patientManager.cachePatient.heightMeasurement = .inches
                driver.patientManager.cachePatient.weightMeasurement = .pounds
            } else if newValue == .centimeters {
                driver.weightUnit = .kilograms
                driver.patientManager.cachePatient.heightMeasurement = .centimeters
                driver.patientManager.cachePatient.weightMeasurement = .kilograms
            }
            if newValue == .inches && driver.weightUnit == .kilograms {
                showError = true
            } else if newValue == .centimeters && driver.weightUnit == .pounds {
                showError = true
            } else {
                showError = false
            }
            driver.patientManager.cachePatient.bmi = driver.bmiValue
        }
        .onChange(of: driver.selectedHeight) { newValue in
            driver.patientManager.cachePatient.heightIn = Int(newValue) ?? 0
            driver.patientManager.cachePatient.bmi = driver.bmiValue
        }
    }

    @ViewBuilder
    var weightField: some View {
        InputField(
            R.string.localizable.weight(),
            placeholder: "Enter",
            inputTxt: $driver.selectedWeight,
            requirement: $driver.weightUnit,
            charCount: 4
        )
        .padding(.bottom, 18)
        .onChange(of: driver.weightUnit) { newValue in
            if newValue == .pounds {
                driver.heightUnit = .inches
                driver.patientManager.cachePatient.weightMeasurement = .pounds
                driver.patientManager.cachePatient.heightMeasurement = .inches
            } else if newValue == .kilograms {
                driver.heightUnit = .centimeters
                driver.patientManager.cachePatient.weightMeasurement = .kilograms
                driver.patientManager.cachePatient.heightMeasurement = .centimeters
            }
            if newValue == .pounds && driver.heightUnit == .centimeters {
                showError = true
            } else if newValue == .kilograms && driver.heightUnit == .inches {
                showError = true
            } else {
                showError = false
            }
            driver.patientManager.cachePatient.bmi = driver.bmiValue
        }
        .onChange(of: driver.selectedWeight) { newValue in
            driver.patientManager.cachePatient.weightLbs = Int(newValue) ?? 0
            driver.patientManager.cachePatient.bmi = driver.bmiValue
        }
    }

    @ViewBuilder
    var bmiField: some View {
        VStack {
            Text("BMI Value")
                .textStyle(.bold)
            TextField("Enter",
                      value: $driver.bmiValue,
                      format: .number)
            .font(.custom("Avenir-Heavy", size: 16))
            .keyboardType(.numberPad)
            .padding(.all, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .defaultShadows()
            )
            .disabled(true)
            HStack {
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.vermillion)
                Text("Mismatched Units")
                    .font(.system(size: 11))
                    .textStyle(.subtitle, color: .vermillion)
            }
            .opacity(showError ? 1 : 0)
        }
    }

    @ViewBuilder
    var sexField: some View {
        TriggerField(
            R.string.localizable.sex(),
            placeholder: R.string.localizable.selectPatientSex(),
            selectedText: $driver.selectedSex
        ) {
            self.dismissKeyboard()
            currentSelection = .sex
            toggleBotSheet()
        }
    }

    @ViewBuilder
    var backButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            Text(R.string.localizable.back())
                .padding(.horizontal, 24)
        })
        .altBtnSecondaryBordered()
    }

    @ViewBuilder
    var goNextButton: some View {
        Button(action: {
            driver.goNextBtnPress {
                if patientFlow == nil {
                    showView.toggle()
                } else {
                    showNextViewInFlow.toggle()
                }
            }
        }, label: {
            Text(goNextStr)
                .frame(maxWidth: .infinity)
        })
        .buttonStyle(driver.canGoNext() ? ALTButtonStyle() : ALTButtonStyle.altBtnIndigoDisabled())
        .disabled(!driver.canGoNext())
    }

    @ViewBuilder
    var saveButton: some View {
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
    }

    @ViewBuilder
    var cancelButton: some View {
        Button(action: {
            patientProfileFlow = nil
        }, label: {
            Text(R.string.localizable.cancel())
                .frame(maxWidth: .infinity)
        })
        .altBtnSecondaryBordered()
    }

    @ViewBuilder
    var backgroundView: some View {
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
    var gradientView: some View {
        VStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color(red: 0.129, green: 0.153, blue: 0.263, opacity: 0),
                        Color(red: 0.129, green: 0.153, blue: 0.263, opacity: 0.3),
                    ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .padding(.top, 200)
    }

    @ViewBuilder
    func bottomSheet(_ geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            BottomSheetView(
                isOpen: $showBotSheet,
                maxHeight: geo.size.height * 0.45
            ) {
                if currentSelection == .sex {
                    SexSheetView(driver: driver, showBotSheet: $showBotSheet)
                    .padding(.bottom, geo.safeAreaInsets.bottom)
                } else if currentSelection == .bodyType {
                    BodyTypeSheetView(driver: driver, showBotSheet: $showBotSheet)
                }
            }
        }
    }

    @ViewBuilder
    var deviceInfoText: some View {
        Text(DeviceConstants.getBuildInfoStr(facilityName: userDefaults.facilityName))
            .textStyle(.overline, color: .silver)
            .multilineTextAlignment(.center)
    }

    var alert: Alert {
        Alert(
            title: Text(R.string.localizable.patientError()),
            message: Text(R.string.localizable.invalidHeightWeight())
        )
    }

    func toggleBotSheet() {
        withAnimation {
            showBotSheet.toggle()
        }
    }
    
    func dismiss() {
        if patientFlow != nil {
            patientFlow = nil
            driver.patientManager.cachePatient.resetCache()
        } else if patientProfileFlow != nil {
            patientProfileFlow = nil
        } else {
            showView = false
        }
    }
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

// MARK: - Preview
struct PatientProfileView_Previews: PreviewProvider {
    static var previews: some View {
        PatientProfileView()
//            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
