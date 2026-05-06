//
//  PatientBuilder.swift
//  SensorSuite
//
//  Created by Josh Franco on 12/4/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

final class PatientBuilder {
    private let container: Container
    private let patientRepository: any PatientRepositoryProtocol

    private(set) var hospitalRoomBed: HospitalRoomBed?
    private(set) var hospitalUnit: HospitalUnitInfo?

    private(set) var heightIn: Int?
    private(set) var weightLbs: Int?
    private(set) var hasPaceMaker: Bool?
    private(set) var hasSternumSkinBroken: Bool?
    private(set) var bioSex: ALTSex?
    private(set) var bioBmi: Double?
    private(set) var patientSensorLocation: String?

    // MARK: - Computed Variable
    var location: PatientLocation? {
        guard
            let unit = hospitalUnit,
            let roomBed = hospitalRoomBed else { return nil }

        return PatientLocation(info: unit, roomBed: roomBed)
    }

    // MARK: - Error Enum
    enum BuilderErr: Error, LocalizedError {
        case incompleteInfo
        case unknownPatient

        var errorDescription: String? {
            switch self {
            case .incompleteInfo:
                return "Incomplete Information"
            case .unknownPatient:
                return "Unknown Patient"
            }
        }
    }

    // MARK: - Init
    init(container: Container = .shared) {
        self.container = container
        self.patientRepository = container.patientRepository.resolve()
    }

    // MARK: - Util
    func setHospital(unit: HospitalUnitInfo, roomBed: HospitalRoomBed) {
        hospitalRoomBed = roomBed
        hospitalUnit = unit
    }

    /// Set Profile Information
    /// - Parameters:
    ///   - height: Height in inches
    ///   - weight: Weight in pounds
    ///   - sex: chosen sex
    ///   - bmi: BMI value
    // swiftlint:disable:next function_parameter_count
    func setProfile(height: Int, weight: Int, paceMaker: Bool, sternumSkinBroken: Bool, sex: ALTSex, bmi: Double, sensorLocation: String) {
        heightIn = height
        weightLbs = weight
        hasPaceMaker = paceMaker
        hasSternumSkinBroken = sternumSkinBroken
        bioSex = sex
        bioBmi = bmi
        patientSensorLocation = sensorLocation
    }

    func setHasSternumSkinBroken(hasSkinBroken: Bool) {
        hasSternumSkinBroken = hasSkinBroken
    }

    func validatePatient(validationResult: @escaping (Result<ALTPatient, Error>) -> Void) {
        guard let roomBed = hospitalRoomBed,
              let height = heightIn,
              let weight = weightLbs,
              let hasPaceMaker = hasPaceMaker,
              let hasSternumSkinBroken = hasSternumSkinBroken,
              let sex = bioSex,
              let bmi = bioBmi else {
            return validationResult(.failure(BuilderErr.incompleteInfo))
        }

        let newPatient = ALTPatient(
            hospitalRoomBedId: roomBed.id,
            heightIn: height,
            weightLbs: weight,
            hasPaceMaker: hasPaceMaker,
            hasSternumSkinBroken: hasSternumSkinBroken,
            sex: sex,
            bmi: bmi,
            props: ""
        )

        patientRepository.saveToDB(newPatient) { [self] result in
            switch result {
            case .success:
                self.patientRepository.loadIdFromDB(newPatient.id) { result in
                    switch result {
                    case .success(let patient):
                        guard let patientInfo = patient else {
                            validationResult(.failure(BuilderErr.unknownPatient))
                            return
                        }
                        validationResult(.success(patientInfo))
                    case .failure:
                        validationResult(.failure(BuilderErr.unknownPatient))
                    }
                }
            case .failure(let error):
                validationResult(.failure(error))
            }
        }
    }
}
