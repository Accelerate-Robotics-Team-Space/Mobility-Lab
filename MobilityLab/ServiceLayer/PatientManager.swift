//
//  PatientManager.swift
//  MobilityLab
//
//  Created by Josh Franco on 2/22/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol PatientManagerProtocol: AnyObject {
    var currentPatient: ALTPatient? { get }
    var turningProto: TurningProtocol { get }
    var patientLocation: PatientLocation? { get }
    var builder: PatientBuilder? { get }
    var session: SessionServiceProtocol? { get }
    var cachePatient: ALTPatient { get set }
    var wearables: [Wearable] { get }
    var posToAvoid: [PositionalFlagCategory] { get }
    var isSessionInProgress: Bool { get }
    var turnTrackerInfo: TurnTrackerInfo? { get }
    var notifications: [ALTNotification] { get }
    var sessionId: String? { get }
    var delegate: PatientMonitorDriverLocationDelegate? { get set }
    func loadSession(sessionId: String) async -> Bool
    func startSession(posToAvoid: [PositionalFlagCategory], result: @escaping (Result<(), Error>) -> Void)
    func startDevSession() async
    @MainActor func stopSession()
    func updatePatientLocation(hospitalUnit: HospitalUnitInfo, roomBed: HospitalRoomBed)

    func updatePatientProfile(id: String, update profileUpdate: ALTPatient.ProfileUpdate)

    func updatePosToAvoid(_ posToAvoid: [PositionalFlagCategory])
    func uploadPatientInfo()
    func resetRouter()
}

extension Container {
    var patientManager: Factory<PatientManagerProtocol> {
        self { PatientManager(isPreview: false) }.cached
    }
}

final class PatientManager: PatientManagerProtocol {
    static let preview = PatientManager(isPreview: true)

    private let router: MqttRouter<DataFeedTopics>
    private(set) var currentPatient: ALTPatient?
    private(set) var turningProto: TurningProtocol
    private(set) var patientLocation: PatientLocation? {
        didSet {
            if let location = patientLocation {
                Task { [weak self] in
                    guard let self = self, let patient = self.currentPatient else { return }
                    self.currentPatient = await self.patientRepository.updateLocation(for: patient, to: location)
                }
            }
        }
    }
    
    private(set) var builder: PatientBuilder?
    private let injectedBuilder: PatientBuilder?
    private(set) var session: SessionServiceProtocol? {
        didSet {
            if session == nil {
                currentPatient = nil
                patientLocation = nil
            }
        }
    }
    private var sessionBatteryTimer: Timer?
    var cachePatient = ALTPatient()
    
    // MARK: - Computed Variables
    var wearables: [Wearable] {
        session?.activeWearablesArr ?? []
    }
    
    var posToAvoid: [PositionalFlagCategory] {
        session?.posToAvoidArr ?? []
    }
    
    var isSessionInProgress: Bool {
        session != nil
    }
    
    var turnTrackerInfo: TurnTrackerInfo? {
        session?.turnTrackerInfo
    }
    
    var notifications: [ALTNotification] {
        session?.notificationsArr ?? []
    }
    
    var sessionId: String? {
        session?.currentSession.id
    }

    // MARK: Services
    private let container: Container
    private let activityLogRepository: any ActivityLogRepositoryProtocol
    private let hospitalUnitRepository: any HospitalUnitRepositoryProtocol
    private let notificationCenter: NotificationCenterServiceProtocol
    private let patientRepository: any PatientRepositoryProtocol
    private let provisioningAPIService: ProvisioningAPIServiceProtocol
    private let securityService: SecurityServiceProtocol
    private let sessionRepository: any SessionRepositoryProtocol
    private let userDefaults: BMMUserDefaultsServiceProtocol
    private var syncManager: SyncManagerProtocol { container.syncManager.resolve() }

    weak var delegate: PatientMonitorDriverLocationDelegate?
    
    // MARK: - Init
    init(isPreview: Bool, container: Container = .shared, builder: PatientBuilder? = nil) {
        self.container = container
        self.securityService = container.securityService.resolve()
        self.provisioningAPIService = container.provisioningAPIService.resolve()
        self.userDefaults = container.userDefaults.resolve()
        self.notificationCenter = container.notificationCenter.resolve()
        self.activityLogRepository = container.activityLogRepository.resolve()
        self.hospitalUnitRepository = container.hospitalUnitRepository.resolve()
        self.patientRepository = container.patientRepository.resolve()
        self.sessionRepository = container.sessionRepository.resolve()
        self.router = MqttRouter(for: DataFeedTopics.self, container: container)
        self.injectedBuilder = builder
        self.builder = builder ?? PatientBuilder(container: container)
        
        switch ALTEnvironment.current {
        case .dev, .qa:
            self.turningProto = .superShort
        case .test:
            self.turningProto = .dev
        case .prod:
            self.turningProto = .q2Turn
        }
        
        guard !isPreview else {
            patientLocation = .dev
            return
        }
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.securityService.isDeviceRegistered {
                self.router.publish(
                    .batteryLvl(lvl: DeviceConstants.getBatLvl()),
                    to: .batteryLvl(facilityID: userDefaults.facilityId, baseStationGuid: userDefaults.baseStationGuid)
                )
            }
        }
        router.publish(.appVersion(ver: DeviceConstants.versionNumStr), to: .appVersion(facilityID: userDefaults.facilityId, baseStationGuid: userDefaults.baseStationGuid))

        notificationCenter.addObserver(self, selector: #selector(batteryLevelDidChange), name: DeviceConstants.batteryDidChangeName, object: nil)
    }
    
    func loadSession(sessionId: String) async -> Bool {
        do {
            self.session = try await SessionService.getSessionService(resume: sessionId, router: self.router, container: container)
        } catch {
            return false
        }

        guard let patient = self.session!.currentSession.patient else { return false }

        self.currentPatient = patient
        let allUnits = await hospitalUnitRepository.getAll()
        let unit = allUnits.first { unit in
            return unit.id == self.currentPatient!.roomBed!.facilityUnitId
        }!
        let roomBed = unit.roomBeds.first { roomBed in
            return roomBed.id == self.currentPatient!.hospitalRoomBedId
        }!
        let location = PatientLocation(info: unit, roomBed: roomBed)
        publishNewPatient(currentPatient!, at: location)
        patientLocation = location
        builder = nil

        publishBattery()

        if let log = activityLogRepository.withLatestEndDate() {
            session?.updateTurnTrackingInfo(log)
        }

        return true
    }
    
    // MARK: - Session Util
    func startSession(posToAvoid: [PositionalFlagCategory], result: @escaping (Result<(), Error>) -> Void) {
        guard let builder else {
            let error = PatientManagerError.noBuilder
            logger.error("\(type(of: error.self)) \(error)")
            result(.failure(error))
            return
        }
        guard let location = builder.location else {
            let error = PatientManagerError.noLocation
            logger.error("\(type(of: error.self)) \(error)")
            result(.failure(error))
            return
        }

        builder.validatePatient { [self] validationResult in
            switch validationResult {
            case .success(let newPatient):
                Task { [self] in
                    do {
                        self.session = try await SessionService.getSessionService(
                            for: newPatient,
                            router: self.router,
                            turningProto: self.turningProto,
                            posToAvoid: posToAvoid,
                            container: self.container
                        )
                        let patient = self.session?.currentSession.patient ?? newPatient
                        self.currentPatient = patient
                        self.patientLocation = location
                        
                        var props = "{\"avoid\":\""
                        for eAvoid in posToAvoid {
                            props += eAvoid.abbreviation
                        }
                        props += "\"}"
                        let propsTask = props
                        
                        if let currentPatient = self.currentPatient {
                            self.currentPatient = await self.patientRepository.updateProps(for: currentPatient, to: propsTask)
                        }
                        do {
                            let response = try await self.provisioningAPIService.addNewPatient(
                                .init(
                                    baseStationId: self.userDefaults.baseStationGuid!,
                                    facilityId: self.userDefaults.facilityId!,
                                    patientDetails: .init(
                                        patientId: patient.id,
                                        sex: patient.sex,
                                        weight: patient.weightLbs,
                                        height: patient.heightIn,
                                        bmi: patient.bmi,
                                        hasPaceMaker: patient.hasPaceMaker,
                                        hasSternumSkinBroken: patient.hasSternumSkinBroken,
                                        roomBedId: patient.hospitalRoomBedId,
                                        facilityUnitId: patient.roomBed!.facilityUnitId,
                                        turnProtocol: self.userDefaults.turnProtocol!.rawValue,
                                        complianceDegree: self.userDefaults.complianceAngle!.intValue,
                                        sensorLocation: ""
                                    )
                                )
                            )
                            if let exception = response["exceptionCode"] as? String {
                                self.handleAddNewPatientResponse(.failure(Self.PatientManagerError.addSessionError(exception)), newPatient, completion: result)
                            } else {
                                self.builder = nil
                                let data = response["data"] as? [String: Any]
                                let altPatientId = data?["altPatientId"] as? String ?? ""
                                if let patient = self.currentPatient {
                                    self.currentPatient = await self.patientRepository.updateAltPatientId(for: patient, to: altPatientId)
                                }
                                self.handleAddNewPatientResponse(.success, newPatient, completion: result)
                            }
                        } catch {
                            self.handleAddNewPatientResponse(.failure(error), newPatient, completion: result)
                        }
                    } catch {
                        self.handleAddNewPatientResponse(.failure(error), newPatient, completion: result)
                    }
                }
            case .failure(let error):
                result(.failure(error))
            }
        }
    }

    private func handleAddNewPatientResponse(
		_ result: Result<Void, Error>,
		_ patient: ALTPatient,
		completion: @escaping (Result<(), Error>) -> Void
	) {
        switch result {
        case .failure(let error):
            if let session = session?.currentSession {
                sessionRepository.deleteFromDB(session)
            }
            patientRepository.deleteFromDB(patient)
            self.session = nil
            logger.error(error.localizedDescription)
            completion(.failure(error))
        case .success:
            completion(.success(()))
        }
    }
    
    func startDevSession() async {
        let devPatient = ALTPatient.devPatient

        self.builder = nil
        self.currentPatient = devPatient
        self.session = try? await SessionService.getSessionService(
            for: devPatient,
            router: self.router,
            turningProto: self.turningProto,
            posToAvoid: [],
            container: container
        )
    }
    
    @MainActor
    func stopSession() {
        builder = injectedBuilder ?? PatientBuilder(container: container)
        session?.endSession()
        session = nil
        sessionBatteryTimer?.invalidate()
        sessionBatteryTimer = nil
        syncManager.cleanup { [self] _ in
            self.patientRepository.deleteAllFromDB()
        }
        userDefaults.turnProtocol = .Q2
        userDefaults.complianceAngle = .angle20
    }
    
    // MARK: - Builder Util
    func updatePatientLocation(hospitalUnit: HospitalUnitInfo, roomBed: HospitalRoomBed) {
        guard securityService.isDeviceRegistered else {
            return
        }
        if let builder {
            builder.setHospital(unit: hospitalUnit, roomBed: roomBed)
        } else {
            let newLocation = PatientLocation(info: hospitalUnit, roomBed: roomBed)
            Task { [weak self] in
                guard let self = self, let patient = self.currentPatient else { return }
                self.currentPatient = await patientRepository.updateLocation(for: patient, to: newLocation)
            }
            patientLocation = newLocation

            if roomBed.roomBedNumber != nil {
                let topic: DataFeedTopics = .patientLocation(
                    facilityID: userDefaults.facilityId,
                    baseStationGuid: userDefaults.baseStationGuid
                )
                router.publish(.patientLocation(locStr: roomBed), to: topic)
            }

            delegate?.locationUpdated(hospitalRoomBedId: roomBed.id)
        }
    }
    
    func updatePatientProfile(id: String, update profileUpdate: ALTPatient.ProfileUpdate) {
        guard securityService.isDeviceRegistered else {
            return
        }
        if let builder {
            builder.setProfile(
                height: profileUpdate.height,
                weight: profileUpdate.weight,
                paceMaker: profileUpdate.hasPaceMaker,
                sternumSkinBroken: profileUpdate.hasSternumSkinBroken,
                sex: profileUpdate.sex,
                bmi: profileUpdate.bmi,
                sensorLocation: profileUpdate.sensorLocation
            )
        } else {
            Task {
                do {
                    guard let updated = try await self.patientRepository.update(patientID: id, profile: profileUpdate) else {
                        logger.error("Failed to update patient profile")
                        return
                    }
                    self.currentPatient = updated
                } catch {
                    logger.error(error.localizedDescription)
                }
            }
            
            let patient = PublishablePatient(
                patientId: id,
                sex: profileUpdate.sex,
                weight: profileUpdate.weight,
                height: profileUpdate.height,
                bmi: profileUpdate.bmi,
                hasPaceMaker: profileUpdate.hasPaceMaker,
                hasSternumSkinBroken: profileUpdate.hasSternumSkinBroken,
                props: profileUpdate.props,
                roomBedId: patientLocation?.roomBed.id ?? "",
                facilityUnitId: patientLocation?.roomBed.facilityUnitId ?? "",
                turnProtocol: userDefaults.turnProtocol!.rawValue,
                complianceDegree: userDefaults.complianceAngle!.intValue
            )
            let topic: DataFeedTopics = .patientInfo(
                facilityID: userDefaults.facilityId,
                baseStationGuid: userDefaults.baseStationGuid
            )
            router.publish(.patientInfo(info: patient), to: topic)
        }
    }
    
    func updatePosToAvoid(_ posToAvoid: [PositionalFlagCategory]) {
        session?.updatePostToAvoid(posToAvoid)
        var toString = "{\"avoid\":\""
        for eAvoid in posToAvoid {
            toString += eAvoid.abbreviation
        }
        toString += "\"}"
		let prop = toString

        Task { [weak self] in
            guard let self = self, let patient = self.currentPatient else { return }
            self.currentPatient = await self.patientRepository.updateProps(for: patient, to: prop)
            self.uploadPatientInfo()
        }
    }

    func uploadPatientInfo() {
        guard let currentPatient else { return }
        let patient = PublishablePatient(
            patientId: currentPatient.id,
            sex: currentPatient.sex,
            weight: currentPatient.weightLbs,
            height: currentPatient.heightIn,
            bmi: currentPatient.bmi,
            hasPaceMaker: currentPatient.hasPaceMaker,
            hasSternumSkinBroken: currentPatient.hasSternumSkinBroken,
            props: currentPatient.props,
            roomBedId: currentPatient.hospitalRoomBedId,
            facilityUnitId: currentPatient.roomBed?.facilityUnitId ?? "",
            turnProtocol: userDefaults.turnProtocol!.rawValue,
            complianceDegree: userDefaults.complianceAngle!.intValue,
            sensorLocation: ""
        )
        let topic: DataFeedTopics = .patientInfo(
            facilityID: userDefaults.facilityId,
            baseStationGuid: userDefaults.baseStationGuid
        )
        router.publish(.patientInfo(info: patient), to: topic)
    }

    func resetRouter() {
        router.resetIsPublishing()
    }
}

// MARK: - Private
private extension PatientManager {
    enum PatientManagerError: Error, LocalizedError {
        case noBuilder
        case noLocation
        case addSessionError(String)

        var errorDescription: String? {
            switch self {
            case .noBuilder, .noLocation:
                return "Not enough information about the patient to start a session."
            case .addSessionError(let message):
                return "\(message)"
            }
        }
    }
    
    func publishNewPatient(_ patient: ALTPatient, at location: PatientLocation) {
        guard securityService.isDeviceRegistered else {
            return
        }
        var toString = "{\"avoid\":\""
        if let session {
            for posToAvoid in session.posToAvoidArr {
                toString += posToAvoid.abbreviation
            }
        }
        toString += "\"}"
        let prop = toString
        if let patient = self.currentPatient {
            Task { [weak self] in
                guard let self else { return }
                self.currentPatient = await self.patientRepository.updateProps(for: patient, to: prop)
            }
        }

        let publishable = PublishablePatient(
            patient: patient,
            updatedProps: prop,
            facilityUnitID: userDefaults.facilityId ?? "",
            turnProtocol: userDefaults.turnProtocol ?? .Q2,
            complianceDegree: userDefaults.complianceAngle ?? .angle20
        )

        // Publish patient info
        let patientTopicResult: DataFeedTopics.TopicResult = .patientInfo(info: publishable)
        let patientFeedTopic: DataFeedTopics = .patientInfo(
            facilityID: userDefaults.facilityId,
            baseStationGuid: userDefaults.baseStationGuid
        )
        self.router.publish(patientTopicResult, to: patientFeedTopic)

        // Publish location info
        let locationTopicResult: DataFeedTopics.TopicResult = .patientLocation(locStr: location.roomBed)
        let locationFeedTopic: DataFeedTopics = .patientLocation(
            facilityID: userDefaults.facilityId,
            baseStationGuid: userDefaults.baseStationGuid
        )
        self.router.publish(locationTopicResult, to: locationFeedTopic)
    }
    
    @objc
    func batteryLevelDidChange() {
        if securityService.isDeviceRegistered {
            router.publish(
                .batteryLvl(lvl: DeviceConstants.getBatLvl()),
                to: .batteryLvl(facilityID: userDefaults.facilityId, baseStationGuid: userDefaults.baseStationGuid)
            )
        }
    }

    func publishBattery() {
        if securityService.isDeviceRegistered {
            sessionBatteryTimer?.invalidate()
            sessionBatteryTimer = nil
            sessionBatteryTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
                self?.router.publish(
                    .batteryLvl(lvl: DeviceConstants.getBatLvl()),
                    to: .batteryLvl(facilityID: self?.userDefaults.facilityId, baseStationGuid: self?.userDefaults.baseStationGuid)
                )
            }
            sessionBatteryTimer?.fire()
            router.publish(
                .appVersion(ver: DeviceConstants.versionNumStr),
                to: .appVersion(facilityID: userDefaults.facilityId, baseStationGuid: userDefaults.baseStationGuid)
            )
        }
    }
}
