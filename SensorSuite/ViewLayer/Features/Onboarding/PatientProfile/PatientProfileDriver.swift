//
//  PatientProfileDriver.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/18/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

final class PatientProfileDriver: ObservableObject {
    @Published var selectedHeight: String {
        didSet {
            updateBMI()
        }
    }
    @Published var heightUnit = Requirement.inches {
        didSet {
            updateBMI()
        }
    }
    @Published var selectedWeight: String {
        didSet {
            updateBMI()
        }
    }
    @Published var weightUnit = Requirement.pounds {
        didSet {
            updateBMI()
        }
    }
    @Published var selectedSex: String?
    @Published var selectedBodyType: String?
    @Published var bmiValue: Double
    @Published var showInvalidPatientAlert: Bool = false

    let patientManager: PatientManagerProtocol
    let heightInchesRange = Array(0...255)
    let weightLbRange = Array(0...1500)

    let heightCmRange = Array(0...648)
    let weightKgRange = Array(0...682)

    let sexRange = ALTSex.allCases
    let bodyTypeRange = ALTBodyType.allCases
    var hasSternumSkinBroken: Bool?

    private(set) var heightFtIndex: Int?
    private(set) var heightInIndex: Int?
    private(set) var weightIndex: Int?
    private(set) var hasPaceMaker: Bool?
    private(set) var sexIndex: Int?
    private(set) var bodyTypeIndex: Int?

    enum ProfileType {
        case height(height: String)
        case weight(weight: String)
        case sex(index: Int)
        case bodyType(index: Int)
    }
    
    // MARK: - Init
    init(manager: PatientManagerProtocol? = nil, container: Container = .shared) {
        self.patientManager = manager ?? container.patientManager.resolve()
        self.selectedBodyType = ALTBodyType.muscular.description
        self.bodyTypeIndex = 1
        self.heightUnit = self.patientManager.cachePatient.heightMeasurement
        self.weightUnit = self.patientManager.cachePatient.weightMeasurement
        self.hasPaceMaker = self.patientManager.cachePatient.hasPaceMaker
        self.hasSternumSkinBroken = self.patientManager.cachePatient.hasSternumSkinBroken
        self.selectedHeight = self.patientManager.cachePatient.heightIn == 0 ? "" : String(self.patientManager.cachePatient.heightIn)
        self.selectedWeight = self.patientManager.cachePatient.weightLbs == 0 ? "" : String(self.patientManager.cachePatient.weightLbs)
        self.bmiValue = self.patientManager.cachePatient.bmi
    }

    func updateBMI() {
        guard selectedWeight.double > 0.0 && selectedHeight.double > 0.0 else {
            bmiValue = 0.0
            return
        }
        if heightUnit == .inches && weightUnit == .pounds {
            bmiValue = round(selectedWeight.double / selectedHeight.double / selectedHeight.double * 703 * 100) / 100
        } else if heightUnit == .centimeters && weightUnit == .kilograms {
            bmiValue = round(selectedWeight.double / (selectedHeight.double * 0.01) / (selectedHeight.double * 0.01) * 100) / 100
        } else {
            bmiValue = 0.0
        }
    }
    
    // MARK: - Util
    func selectIndex(for type: ProfileType) {
        switch type {
        case .height(let height):
            selectedHeight = height
        case .weight(let weight):
            selectedWeight = weight
        case .sex(let index):
            guard sexRange.indices.contains(index) else {
                return
            }
            sexIndex = index
            if sexIndex != -1 {
                selectedSex = sexRange[index].description
            }
        case .bodyType(let index):
            guard bodyTypeRange.indices.contains(index) else {
                return
            }
            bodyTypeIndex = index
            selectedBodyType = bodyTypeRange[index].description
        }
    }
    
    func canGoNext() -> Bool {
        bodyTypeIndex != nil && sexIndex != nil
    }

    func isHeightAndWeightValid() -> Bool {
        if selectedHeight.isEmpty && selectedWeight.isEmpty { return true }

        let weightRange = weightUnit == .kilograms ? weightKgRange : weightLbRange
        let heightRange = heightUnit == .centimeters ? heightCmRange : heightInchesRange

        if let height = Int(selectedHeight), let weight = Int(selectedWeight) {
            return heightRange.contains(height) && weightRange.contains(weight)
        }
        return false
    }

    func goNextBtnPress(completion: @escaping () -> Void) {
        if !isHeightAndWeightValid() {
            showInvalidPatientAlert = true
            return
        }
        guard let hasPaceMaker,
              let hasSternumSkinBroken,
              let sexIndex,
              sexRange.indices.contains(sexIndex),
              bodyTypeIndex != nil else {
            return
        }

        var heightInches = Int(selectedHeight) ?? 0
        var weightPounds = Int(selectedWeight) ?? 0

        if heightUnit == .centimeters && heightInches != 0 {
            heightInches = Int(round(Double(heightInches) / 2.54))
        }
        if weightUnit == .kilograms && weightPounds != 0 {
            weightPounds = Int(round(Double(weightPounds) / 0.45359237))
        }

        let bmi = calculateBmi_Imperial(heightInches: heightInches, weightPounds: weightPounds)

        let toString: String
        if let posToAvoid = patientManager.session?.posToAvoidArr {
            toString = #"{"avoid":""# + posToAvoid.map { $0.abbreviation }.sorted().joined() + #""}"#
        } else {
            toString = #"{"avoid":""}"#
        }

        let id = patientManager.currentPatient?.id ?? ""
        let profileUpdate = ALTPatient.ProfileUpdate(
            height: heightInches,
            weight: weightPounds,
            hasPaceMaker: hasPaceMaker,
            hasSternumSkinBroken: hasSternumSkinBroken,
            sex: sexRange[sexIndex],
            bmi: bmi,
            props: toString,
            altPatientId: patientManager.currentPatient?.altPatientId ?? "",
            sensorLocation: ""
        )

        patientManager.updatePatientProfile(id: id, update: profileUpdate)

        completion()
    }

    private func calculateBmi_Imperial(heightInches: Int, weightPounds: Int) -> Double {
        guard heightInches != 0 && weightPounds != 0 else { return 0.0 }
        return Double(weightPounds) / (Double(heightInches) * Double(heightInches)) * 703
    }

    func getSexIndexFromDescription(description: String) -> Int {
        switch description {
        case ALTSex.male.description:       0
        case ALTSex.female.description:     1
        case ALTSex.other.description:      2
        case ALTSex.noAnswer.description:   3
        default:                            -1
        }
    }
    
    func getBodyTypeIndexFromDescription(description: String) -> Int {
        switch description {
        case ALTBodyType.round.description:     0
        case ALTBodyType.muscular.description:  1
        case ALTBodyType.slim.description:      2
        default:                                -1
        }
    }
}

// MARK: - Private
private extension PatientProfileDriver {
    func updateViewForPatient(_ patient: ALTPatient?) {
        guard let patient else {
            return
        }
        selectIndex(for: .height(height: patient.formattedHeight))
        selectIndex(for: .weight(weight: patient.formattedWeight))
        if let sexIndex = sexRange.firstIndex(of: patient.sex) {
            selectIndex(for: .sex(index: sexIndex))
        }
    }
}
