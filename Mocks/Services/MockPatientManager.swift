//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM

final class MockPatientManager: PatientManagerProtocol {
    typealias UpdatePatientProfileType = (String, Int, Int, Bool, Bool, ALTSex, Double, String, String) // swiftlint:disable:this large_tuple

    var currentPatient: ALTPatient?
    var turningProto: TurningProtocol = .superShort
    var patientLocation: PatientLocation?
    var builder: PatientBuilder?
    var session: SessionServiceProtocol?
    var cachePatient: ALTPatient = .devPatient
    var wearables: [Wearable] = []
    var posToAvoid: [PositionalFlagCategory] = []
    var isSessionInProgress: Bool = false
    var turnTrackerInfo: TurnTrackerInfo?
    var notifications: [ALTNotification] = []
    var sessionId: String?
    var delegate: (any PatientMonitorDriverLocationDelegate)?

    var loadSessionHandler: ((String) async -> Bool)?
    var startSessionHandler: (([PositionalFlagCategory], ((Result<(), any Error>) -> Void)) -> Void)?

    // swiftlint:disable:next large_tuple
    var handleAddNewPatientResponseHandler: (((Result<Void, any Error>, ALTPatient, (Result<(), any Error>) -> Void)) -> Void?)?
    var startDevSessionHandler: (() async -> Void)?
    var stopSessionHandler: (() -> Void)?
    var updatePatientLocationHandler: ((HospitalUnitInfo, HospitalRoomBed) -> Void)?
    var updatePatientProfileHandler: ((UpdatePatientProfileType) -> Void)?
    var updatePosToAvoidHandler: (([PositionalFlagCategory]) -> Void)?
    var uploadPatientInfoHandler: (() -> Void)?
    var resetRouterHandler: (() -> Void)?

    func loadSession(sessionId: String) async -> Bool {
        guard let loadSessionHandler else {
            fatalError("loadSessionHandler must be set")
        }
        return await loadSessionHandler(sessionId)
    }

    func startSession(posToAvoid: [PositionalFlagCategory], result: @escaping (Result<(), any Error>) -> Void) {
        guard let startSessionHandler else {
            fatalError("startSessionHandler must be set")
        }
        startSessionHandler(posToAvoid, result)
    }

    func handleAddNewPatientResponse(
        _ result: Result<Void, any Error>,
        _ patient: ALTPatient,
        completion: @escaping (Result<(), any Error>) -> Void
    ) {
        guard let handleAddNewPatientResponseHandler else {
            fatalError("handleAddNewPatientResponseHandler must be set")
        }
        handleAddNewPatientResponseHandler((result, patient, completion))
    }

    func startDevSession() async {
        guard let startDevSessionHandler else {
            fatalError("startDevSessionHandler must be set")
        }
        await startDevSessionHandler()
    }

    func stopSession() {
        guard let stopSessionHandler else {
            fatalError("stopSessionHandler must be set")
        }
        stopSessionHandler()
    }

    func updatePatientLocation(hospitalUnit: HospitalUnitInfo, roomBed: HospitalRoomBed) {
        guard let updatePatientLocationHandler else {
            fatalError("updatePatientLocationHandler must be set")
        }
        updatePatientLocationHandler(hospitalUnit, roomBed)
    }

    func updatePatientProfile(id: String, update profileUpdate: ALTPatient.ProfileUpdate) {
        guard let updatePatientProfileHandler else {
            fatalError("updatePatientProfileHandler must be set")
        }
        updatePatientProfileHandler(
            (
                id,
                profileUpdate.height,
                profileUpdate.weight,
                profileUpdate.hasPaceMaker,
                profileUpdate.hasSternumSkinBroken,
                profileUpdate.sex,
                profileUpdate.bmi,
                profileUpdate.props,
                profileUpdate.sensorLocation
            )
        )
    }

    func updatePosToAvoid(_ posToAvoid: [PositionalFlagCategory]) {
        guard let updatePosToAvoidHandler else {
            fatalError("updatePosToAvoidHandler must be set")
        }
        updatePosToAvoidHandler(posToAvoid)
    }

    func uploadPatientInfo() {
        guard let uploadPatientInfoHandler else {
            fatalError("uploadPatientInfoHandler must be set")
        }
        uploadPatientInfoHandler()
    }

    func resetRouter() {
        guard let resetRouterHandler else {
            fatalError("resetRouterHandler must be set")
        }
        resetRouterHandler()
    }
}

final class NullPatientManager: PatientManagerProtocol {
    var currentPatient: ALTPatient? {
        fatalError("Null Service Should Not Be Used")
    }

    var turningProto: TurningProtocol {
        fatalError("Null Service Should Not Be Used")
    }

    var patientLocation: PatientLocation? {
        fatalError("Null Service Should Not Be Used")
    }

    var builder: PatientBuilder? {
        fatalError("Null Service Should Not Be Used")
    }

    var session: SessionServiceProtocol? {
        fatalError("Null Service Should Not Be Used")
    }

    var cachePatient: ALTPatient {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var wearables: [Wearable] {
        fatalError("Null Service Should Not Be Used")
    }

    var posToAvoid: [PositionalFlagCategory] {
        fatalError("Null Service Should Not Be Used")
    }

    var isSessionInProgress: Bool {
        fatalError("Null Service Should Not Be Used")
    }

    var turnTrackerInfo: TurnTrackerInfo? {
        fatalError("Null Service Should Not Be Used")
    }

    var notifications: [ALTNotification] {
        fatalError("Null Service Should Not Be Used")
    }

    var sessionId: String? {
        fatalError("Null Service Should Not Be Used")
    }

    var delegate: (any PatientMonitorDriverLocationDelegate)? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    func loadSession(sessionId: String) async -> Bool {
        fatalError("Null Service Should Not Be Used")
    }

    func startSession(posToAvoid: [PositionalFlagCategory], result: @escaping (Result<(), any Error>) -> Void) {
        fatalError("Null Service Should Not Be Used")
    }

    func handleAddNewPatientResponse(
        _ result: Result<Void, any Error>,
        _ patient: ALTPatient,
        completion: @escaping (Result<(), any Error>) -> Void
    ) {
        fatalError("Null Service Should Not Be Used")
    }

    func startDevSession() async {
        fatalError("Null Service Should Not Be Used")
    }

    func stopSession() {
        fatalError("Null Service Should Not Be Used")
    }

    func updatePatientLocation(hospitalUnit: HospitalUnitInfo, roomBed: HospitalRoomBed) {
        fatalError("Null Service Should Not Be Used")
    }

    func updatePatientProfile(id: String, update profileUpdate: ALTPatient.ProfileUpdate) {
        fatalError("Null Service Should Not Be Used")
    }

    func updatePosToAvoid(_ posToAvoid: [PositionalFlagCategory]) {
        fatalError("Null Service Should Not Be Used")
    }

    func uploadPatientInfo() {
        fatalError("Null Service Should Not Be Used")
    }

    func resetRouter() {
        fatalError("Null Service Should Not Be Used")
    }
}
