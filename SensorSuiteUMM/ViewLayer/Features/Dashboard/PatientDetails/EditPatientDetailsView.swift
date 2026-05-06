//
//  EditPatientDetailsView.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 11/17/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct EditPatientDetailsView: View {
    @ObservedObject var patientDetailsViewModel: PatientDetailsViewModel
    @Binding var profileModal: DashboardDriver.ProfileActiveModal
    
    @State var selectedHeightOG: String
    @State var selectedHeight: String
    @State var selectedWeightOG: String
    @State var selectedWeight: String
    @State var bmiValue: String = ""
    @State var selectedSexOG: String
    @State var selectedSex: String
    @State var weightUnit = Requirement.pounds
    @State var heightUnit = Requirement.inches
    @State var errorCase = ErrorCase.none {
        didSet {
            switch errorCase {
            case .mismatchUnitOfMeasurement:
                canGoNext = false
                errorString = "Height and weight should have same units of measurement"
            case .emptyField:
                canGoNext = false
                errorString = "Either Height or Weight is empty or not a number"
            case .negativeValue:
                canGoNext = false
                errorString = "Either Height or Weight is a negative number"
            case .none:
                canGoNext = true
                errorString = "This is a very long hidden text for error message"
            }
        }
    }
    @State var errorString = "This is a very long hidden text for error message"
    @State var canGoNext = true
    @State var picker = DetailsPicker.none
    
    enum DetailsPicker {
        case sex
        case none
    }
    
    enum ErrorCase {
        case mismatchUnitOfMeasurement
        case emptyField
        case negativeValue
        case none
    }
    
    private let altSexArray: [String] = [
        ALTSex.male.description,
        ALTSex.female.description,
        ALTSex.other.description,
        ALTSex.noAnswer.description,
    ]

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
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
                    VStack {
                        Text(R.string.localizable.whatPatientDetails())
                            .font(.custom("Avenir-Heavy", size: 24))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.charcoal)
                    }
                    .padding(.trailing, 24)
                }
                VStack {
                    HStack(spacing: 16) {
                        InputField(R.string.localizable.height(),
                                   placeholder: "Enter height",
                                   inputTxt: $selectedHeight,
                                   requirement: $heightUnit)
                        .padding(.bottom, 18)
                        .onChange(of: heightUnit) { newValue in
                            if newValue == .inches && weightUnit == .kilograms {
                                errorCase = .mismatchUnitOfMeasurement
                            } else if newValue == .centimeters && weightUnit == .pounds {
                                errorCase = .mismatchUnitOfMeasurement
                            } else {
                                errorCase = .none
                            }
                            updateBMI()
                        }
                        .onChange(of: selectedHeight) { _ in
                            updateBMI()
                        }
                        InputField(R.string.localizable.weight(),
                                   placeholder: "Enter weight",
                                   inputTxt: $selectedWeight,
                                   requirement: $weightUnit)
                        .padding(.bottom, 18)
                        .onChange(of: weightUnit) { newValue in
                            if newValue == .pounds && heightUnit == .centimeters {
                                errorCase = .mismatchUnitOfMeasurement
                            } else if newValue == .kilograms && heightUnit == .inches {
                                errorCase = .mismatchUnitOfMeasurement
                            } else {
                                errorCase = .none
                            }
                           updateBMI()
                        }
                        .onChange(of: selectedWeight) { _ in
                            updateBMI()
                        }
                        VStack {
                            Text("BMI Value")
                                .textStyle(.btn)
                            Text(bmiValue)
                                .font(.custom("Avenir-Heavy", size: 16))
                                .padding(.all, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.3))
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 0)
                                        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 0)
                                        .shadow(color: .white, radius: 8, x: 0, y: 0)
                                )
                                .disabled(true)
                            HStack {
                                Circle()
                                    .frame(width: 8, height: 8)
                                    .foregroundColor(.vermillion)
                                Text(errorString)
                                    .font(.system(size: 11))
                                    .textStyle(.subtitle, color: .vermillion)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .opacity(errorCase != .none ? 1 : 0)
                        }
                        .offset(y: 8)
                    }
                    VStack(alignment: .leading) {
                        Text("Sex")
                            .textStyle(.btn)
                        Button(action: {
                            picker = .sex
                        }, label: {
                            HStack {
                                Text(selectedSex)
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .bold()
                                    .foregroundColor(.charcoal1)
                                Spacer()
                                Image(R.image.arrowDown.name)
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(.charcoal)
                                    .frame(width: 12, height: 12)
                            }
                        })
                        .padding(.all, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .defaultShadows()
                        )
                    }
                }
                Spacer()
                VStack(spacing: 16) {
                    Button(action: {
                        patientDetailsViewModel.heightInInches = Int(selectedHeight)
                        patientDetailsViewModel.weightInPounds = Int(selectedWeight)
                        
                        if selectedSex == ALTSex.male.description {
                            patientDetailsViewModel.sex = .male
                        } else if selectedSex == ALTSex.female.description {
                            patientDetailsViewModel.sex = .female
                        } else if selectedSex == ALTSex.other.description {
                            patientDetailsViewModel.sex = .other
                        } else if selectedSex == ALTSex.noAnswer.description {
                            patientDetailsViewModel.sex = .noAnswer
                        }
                        
                        saveAndDismiss()
                    }, label: {
                        Text(R.string.localizable.save())
                            .frame(maxWidth: .infinity)
                    })
                    .flatBtnStyle(.primary(subtype: canGoNext ? .default : .disabled))
                    .disabled(!canGoNext)
                    Button(action: {
                        resetAndDismiss()
                    }, label: {
                        Text(R.string.localizable.cancel())
                            .frame(maxWidth: .infinity)
                    })
                    .buttonStyle(FlatButtonStyle(.clear()))
                }
            }
            .padding()
            .background(
                Rectangle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1),
                            radius: 2,
                            x: 0,
                            y: 0)
            )
            if picker == .sex {
                VStack {
                    HStack {
                        Text("Sex")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.charcoal)
                        Spacer()
                        Button {
                            picker = .none
                        } label: {
                            Text("Done")
                        }
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .frame(height: 32)
                            .foregroundColor(.green1)
                        Picker("Sex", selection: $selectedSex) {
                            ForEach(altSexArray, id: \.self) { item in
                                Text(item)
                                    .tag(item)
                                    .modifier(ColorAnimation(item == selectedSex, from: .white, to: .black))
                            }
                        }
                    }
                    .navigationBarHidden(true)
                    .pickerStyle(.wheel)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 1)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .frame(width: 300, height: 200)
            }
        }
    }
    
    // MARK: - Init
    init(viewModel: PatientDetailsViewModel, flow: Binding<DashboardDriver.ProfileActiveModal>) {
        self.patientDetailsViewModel = viewModel
        
        _selectedHeight = State(initialValue: String(viewModel.heightInInches ?? 0))
        _selectedHeightOG = _selectedHeight
        _selectedWeight = State(initialValue: String(viewModel.weightInPounds ?? 0))
        _selectedWeightOG = _selectedWeight
//        _bmiValue = State(initialValue: String(round((viewModel.bmi ?? 0.0) * 100) / 100))
        _selectedSex = State(initialValue: viewModel.sex!.description)
        _selectedSexOG = _selectedSex
        _profileModal = flow
    }
}

// MARK: - Private
private extension EditPatientDetailsView {
    enum UnitOfMeasurement {
        case imperial
        case metric
    }
    
    func calculateBmi(height: String, weight: String, _ unitOfMeasurement: UnitOfMeasurement = .imperial) -> String {
        let sigfigFormatter = NumberFormatter()
        sigfigFormatter.usesSignificantDigits = true
        sigfigFormatter.minimumSignificantDigits = 2
        sigfigFormatter.maximumSignificantDigits = 2
        var innerHeight = 0.0
        var innerWeight = 0.0
        
        do {
            innerHeight = try Double(value: height)
            innerWeight = try Double(value: weight)
        } catch {
            errorCase = .emptyField
            return "Cannot calculate value"
        }
        
        if innerWeight <= 0 || innerHeight <= 0 {
            errorCase = .negativeValue
            return "Cannot calculate value"
        }
        
        errorCase = .none
        if unitOfMeasurement == .imperial {
            let bmiCalculated = (innerWeight / innerHeight / innerHeight * 703 * 100).rounded() / 100
            return String(bmiCalculated)
        } else {
            let heightToMeter = innerHeight * 0.01
            let bmiCalculated = ((innerWeight / (heightToMeter * heightToMeter)) * 100).rounded() / 100
            return String(bmiCalculated)
        }
    }
    func resetAndDismiss() {
        selectedHeight = selectedHeightOG
        selectedWeight = selectedWeightOG
        selectedSex = selectedSexOG
        withAnimation(.spring().speed(1.3)) {
            profileModal = .none
        }
    }
    func saveAndDismiss() {
        selectedHeightOG = selectedHeight
        selectedWeightOG = selectedWeight
        selectedSexOG = selectedSex
        withAnimation(.spring().speed(1.3)) {
            profileModal = .none
        }
    }
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    func updateBMI() {
        if heightUnit == .inches && weightUnit == .pounds {
            bmiValue = calculateBmi(height: selectedHeight, weight: selectedWeight)
        } else if heightUnit == .centimeters && weightUnit == .kilograms {
            bmiValue = calculateBmi(height: selectedHeight, weight: selectedWeight, .metric)
        } else {
            bmiValue = "Cannot calculate value"
        }
    }
}

struct EditPatientDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        EditPatientDetailsView(viewModel: PatientDetailsViewModel(id: "an id"),
                               flow: .constant(.details))
    }
}
