//
//  DashboardSettingPatientProfileView.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 3/9/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct DashboardSettingPatientProfileView: View {
    @Binding var patientProfileFlow: ProfileDriver.ProfileActiveModal?

    @State var selectedHeightOG: String
    @State var selectedHeight: String
    @State var selectedWeightOG: String
    @State var selectedWeight: String
    @State var bmiValue: Double
    @State var selectedSexOG: String?
    @State var selectedSex: String?
    @State var currentSelection = PatientProfileSelection.sex
    @State var weightUnit = Requirement.pounds
    @State var heightUnit = Requirement.inches
    @State var showBotSheet: Bool = false
    @State var showError: Bool = false

    @StateObject private var patientProfileDriver = PatientProfileDriver()

    private var goNextStr: String {
        return R.string.localizable.continue()
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                if patientProfileFlow == nil {
                    VStack {}
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }

                mainVStack(geo)

                if showBotSheet {
                    gradient
                }

                bottomSheet(geo)
            }
            .padding(.bottom, -geo.safeAreaInsets.bottom)
            .background(Color.white.opacity(0.1))
        }
        .navigationBarHidden(true)
        .onTapGesture {
            self.dismissKeyboard()
        }
        .alert(Text(R.string.localizable.patientError()), isPresented: $patientProfileDriver.showInvalidPatientAlert) {
            Button(R.string.localizable.ok()) { } // alert dismisal
        } message: {
            Text(R.string.localizable.invalidHeightWeight())
        }
    }

    @ViewBuilder
    func mainVStack(_ geo: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            subView1

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

            saveButton
                .padding(.bottom, geo.safeAreaInsets.bottom)
        }
        .padding()
        .background(mainVStackBackground)
    }

    @ViewBuilder
    var subView1: some View {
        VStack(alignment: .leading) {
            if patientProfileFlow == nil {
                step2Of4View
            }

            VStack(alignment: .leading) {
                editDetailsButton
            }
            VStack {
                whatPatientView
            }
            .padding(.trailing, 24)
        }
    }

    @ViewBuilder
    var step2Of4View: some View {
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
    var editDetailsButton: some View {
        HStack {
            Text(R.string.localizable.editDetails())
                .font(.custom("Avenir-Heavy", size: 24))
                .foregroundColor(.charcoal3)

            Spacer()
            Button(action: {
                resetAndDismiss()
            }) {
                Image(R.image.cross.name)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.charcoal3)
            }
        }
    }

    @ViewBuilder
    var whatPatientView: some View {
        Text(R.string.localizable.whatPatientDetails())
            .font(.custom("Avenir-Heavy", size: 24))
            .multilineTextAlignment(.leading)
            .foregroundColor(.charcoal)
    }

    @ViewBuilder
    var heightField: some View {
        InputField(
            R.string.localizable.height(),
            placeholder: "Enter",
            inputTxt: $selectedHeight,
            requirement: $heightUnit,
            charCount: 3
        )
        .padding(.bottom, 18)
        .onChange(of: heightUnit) { newValue in
            if newValue == .inches {
                selectedHeight = "\(Int(round(selectedHeight.double / 2.54)))"
                weightUnit = .pounds
            } else if newValue == .centimeters {
                selectedHeight = "\(Int(round(selectedHeight.double * 2.54)))"
                weightUnit = .kilograms
            }
            if newValue == .inches && weightUnit == .kilograms {
                showError = true
            } else if newValue == .centimeters && weightUnit == .pounds {
                showError = true
            } else {
                showError = false
            }
            updateBMI(height: selectedHeight.double, weight: selectedWeight.double)
        }
        .onChange(of: selectedHeight) { newHeightValue in
            updateBMI(height: newHeightValue.double, weight: selectedWeight.double)
        }
    }

    @ViewBuilder
    var weightField: some View {
        InputField(
            R.string.localizable.weight(),
            placeholder: "Enter",
            inputTxt: $selectedWeight,
            requirement: $weightUnit,
            charCount: 4
        )
        .padding(.bottom, 18)
        .onChange(of: weightUnit) { newValue in
            if newValue == .pounds {
                selectedWeight = "\(Int(round(selectedWeight.double * 2.2)))"
                heightUnit = .inches
            } else if newValue == .kilograms {
                selectedWeight = "\(Int(round(selectedWeight.double / 2.2)))"
                heightUnit = .centimeters
            }
            if newValue == .pounds && heightUnit == .centimeters {
                showError = true
            } else if newValue == .kilograms && heightUnit == .inches {
                showError = true
            } else {
                showError = false
            }
            updateBMI(height: selectedHeight.double, weight: selectedWeight.double)
        }
        .onChange(of: selectedWeight) { newWeightValue in
            updateBMI(height: selectedHeight.double, weight: newWeightValue.double)
        }
    }

    @ViewBuilder
    var bmiField: some View {
        VStack {
            Text("BMI Value")
                .textStyle(.bold)
            TextField("Enter",
                      value: $bmiValue,
                      format: .number)
            .font(.custom("Avenir-Heavy", size: 16))
            .keyboardType(.numberPad)
            .padding(.all, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 0)
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
            selectedText: $selectedSex
        ) {
            self.dismissKeyboard()
            currentSelection = .sex
            toggleBotSheet()
        }
    }

    @ViewBuilder
    var saveButton: some View {
        VStack(spacing: 16) {
            Button(action: {
                patientProfileDriver.heightUnit = heightUnit
                patientProfileDriver.weightUnit = weightUnit
                patientProfileDriver.selectedHeight = selectedHeight
                patientProfileDriver.selectedWeight = selectedWeight
                patientProfileDriver.selectIndex(
                    for: .sex(index: patientProfileDriver.getSexIndexFromDescription(description: selectedSex!))
                )

                patientProfileDriver.goNextBtnPress {
                    saveAndDismiss()
                }
            }, label: {
                Text(R.string.localizable.save())
                    .frame(maxWidth: .infinity)
            })
            .altBtnIndigo()
            Button(action: {
                resetAndDismiss()
            }, label: {
                Text(R.string.localizable.cancel())
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(FlatButtonStyle(.clear()))
        }
    }

    @ViewBuilder
    var mainVStackBackground: some View {
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
    var gradient: some View {
        VStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color(red: 0.129, green: 0.153, blue: 0.263, opacity: 0),
                        Color(red: 0.129, green: 0.153, blue: 0.263, opacity: 0.3),
                    ]
                ),
                startPoint: .top,
                endPoint: .bottom)
        }
        .padding(.top, 200)
    }

    @ViewBuilder
    func bottomSheet(_ geo: GeometryProxy) -> some View {
        BottomSheetView(
            isOpen: $showBotSheet,
            maxHeight: geo.size.height * 0.45
        ) {
            if currentSelection == .sex {
                DashboardSexSheetView(
                    selectedSex: $selectedSex.toUnwrapped(defaultValue: ALTSex.female.rawValue),
                    showBotSheet: $showBotSheet
                )
                .padding(.bottom, geo.safeAreaInsets.bottom)
            }
        }
    }

    // MARK: - Init
    init(using manager: PatientManagerProtocol? = nil, flow: Binding<ProfileDriver.ProfileActiveModal?>) {
        let manager = manager ?? Container.shared.patientManager.resolve()
        _selectedHeight = State(initialValue: (manager.currentPatient?.formattedHeight ?? ""))
        _selectedHeightOG = _selectedHeight
        _selectedWeight = State(initialValue: (manager.currentPatient?.formattedWeight ?? ""))
        _selectedWeightOG = _selectedWeight
        if let bmi = manager.currentPatient?.bmi {
            _bmiValue = State(initialValue: round(bmi * 100) / 100)
        } else {
            _bmiValue = State(initialValue: 0)
        }
        _selectedSex = State(initialValue: (manager.currentPatient?.sex.description ?? ALTSex.noAnswer.rawValue))
        _selectedSexOG = _selectedSex
        _patientProfileFlow = flow
    }

    private func updateBMI(height: Double, weight: Double) {
        guard height > 0.0 && weight > 0.0 else {
            bmiValue = 0.0
            return
        }
        if heightUnit == .inches && weightUnit == .pounds {
            bmiValue = round(weight / height / height * 703 * 100) / 100
        } else if heightUnit == .centimeters && weightUnit == .kilograms {
            bmiValue = round(weight / (height * 0.01) / (height * 0.01) * 100) / 100
        } else {
            bmiValue = 0.0
        }
    }
}

// MARK: - Private
private extension DashboardSettingPatientProfileView {
    func toggleBotSheet() {
        withAnimation {
            showBotSheet.toggle()
        }
    }
    func resetAndDismiss() {
        selectedHeight = selectedHeightOG
        selectedWeight = selectedWeightOG
        selectedSex = selectedSexOG
        heightUnit = .inches
        weightUnit = .pounds
        withAnimation(.spring().speed(1.3)) {
            patientProfileFlow = nil
        }
    }
    func saveAndDismiss() {
        selectedHeightOG = selectedHeight
        selectedWeightOG = selectedWeight
        selectedSexOG = selectedSex
        withAnimation(.spring().speed(1.3)) {
            patientProfileFlow = nil
        }
    }
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

struct DashboardSettingPatientProfileView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardSettingPatientProfileView(flow: .constant(nil))
    }
}
