//
//  PatientLandingDriver.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/16/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import AVFoundation
import Combine
import CoreBluetooth
import FactoryKit
import Foundation
import SwiftUI

final class PatientLandingDriver: ObservableObject {
    @Published var isDevMode: Bool = false
    @Published var isTestMode: Bool = false
    @Published var isRegistered: Bool = false
    @Published var showAlert: Bool = false
    @Published var showAdminPanel: Bool = false
    @Published var modal: ActiveModal?
    @Published var currentScreen: CurrentScreen = .landing

    private(set) var actionSheetBtns: [String: (() -> Void)?] = [:]
    private(set) var alertTitle: String = "?"
    private(set) var alertBody: String = "?"
    private(set) var shouldContinueExistingSession: Bool = false
    private var cancellables: Set<AnyCancellable> = []
    #if DEV || QA
    private(set) var deviceModel: String = "Unknown"
    #endif

    enum ActiveModal: Identifiable {
        case devMenu
        case newPatient

        var id: Int {
            hashValue
        }
    }

    enum CurrentScreen {
        case landing
        case greet
        case dashboard
        case demoDashboard

        var backgroundColor: Color {
            switch self {
            case .landing:
                return .aqua5
            case .greet:
                return .indigoBkgd
            case .dashboard, .demoDashboard:
                return .clear
            }
        }
    }

    // MARK: Services
    private let container: Container
    private let activityLogRepository: any ActivityLogRepositoryProtocol
    private let patientRepository: any PatientRepositoryProtocol
    private let sessionRepository: any SessionRepositoryProtocol
    private let notificationCenter: NotificationCenterServiceProtocol
    private let securityService: SecurityServiceProtocol
    private let mqttService: MQTTServiceProtocol
    private let userDefaults: BMMUserDefaultsServiceProtocol
    private let provisioningAPIService: ProvisioningAPIServiceProtocol
    private let patientManager: PatientManagerProtocol
    private let syncManager: SyncManagerProtocol
    private var cbManager: CBCentralManager?

    // MARK: - Init
    init(container: Container = .shared) {
        self.container = container
        self.activityLogRepository = container.activityLogRepository.resolve()
        self.patientRepository = container.patientRepository.resolve()
        self.sessionRepository = container.sessionRepository.resolve()
        self.notificationCenter = container.notificationCenter.resolve()
        self.securityService = container.securityService.resolve()
        self.mqttService = container.mqttService.resolve()
        self.userDefaults = container.userDefaults.resolve()
        self.provisioningAPIService = container.provisioningAPIService.resolve()
        self.patientManager = container.patientManager.resolve()
        self.syncManager = container.syncManager.resolve()

        isDevMode = ALTEnvironment.current == .dev || ALTEnvironment.current == .qa
        isTestMode = ALTEnvironment.current == .test
        isRegistered = securityService.isDeviceRegistered
        notificationCenter.addObserver(self, selector: #selector(revokedHandler), name: SecurityService.revokedNote, object: nil)

        setupActionSheet()

        checkForExistingSessionAndMoveToDashboard()
        requestBluetoothPermission()

        DispatchQueue.global().async { [weak self] in
            self?.securityService.resetAllIsCurrent()
        }
#if DEV || QA
        Task {
            self.deviceModel = await DeviceConstants.modelName()
        }
#endif
    }

    func updateRegistrationState() {
        isRegistered = securityService.isDeviceRegistered
        if isRegistered {
            self.cbManager = nil
            mqttService.startSession()
        }
    }

    var buildInfo: String {
        DeviceConstants.getBuildInfoStr(facilityName: userDefaults.facilityName)
    }

    var deviceID: String {
        userDefaults.baseStationFromApple ?? "?"
    }

    func getFacilityConfig(completion: @escaping (Bool) -> Void) {
        guard let facilityId = userDefaults.facilityId else { return }
        provisioningAPIService.getConfig(facilityId)
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    completion(true)
                case .failure(let error):
                    logger.error(error.localizedDescription)
                    completion(false)
                }
            }, receiveValue: { [weak self] facilityConfig in
                self?.userDefaults.turnProtocol = TurnProtocol(rawValue: facilityConfig.turnProtocol) ?? .Q2
                self?.userDefaults.complianceAngle = ComplianceAngle(fromInt: facilityConfig.complianceDegree) ?? .angle20
                self?.userDefaults.isComplianceEnabled = facilityConfig.enableCompliance ?? false
                self?.userDefaults.isTurnProtocolEnabled = facilityConfig.enableTurnProtocol ?? false
            })
            .store(in: &cancellables)
    }

    func getLastSessionIfExists() async -> ALTSession? {
        if userDefaults.defaultingBaseStationFromApple != UserDefaults.defaultBaseStationID {
            guard let lastSession = await sessionRepository.getLastSession() else {
                return nil
            }
            if !lastSession.hasEnded {
                // there was an active session
                if await patientManager.loadSession(sessionId: lastSession.id) {
                    return lastSession
                }
            }
        }

        return nil
    }
}

// MARK: - Private
private extension PatientLandingDriver {
    @objc
    func revokedHandler() {
        isRegistered = securityService.isDeviceRegistered
    }

    func setupActionSheet() {
        actionSheetBtns["Check CRL"] = { [weak self] in
            self?.securityService.checkCertificateRevocationList()
        }
        actionSheetBtns["Reset Registration"] = { [weak self] in
            self?.securityService.resetDeviceRegistered()
        }
        actionSheetBtns["Generate Crash"] = {
            fatalError("User generated Crash")
        }
    }

    func requestCameraAuthIfNeeded() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if !granted {
                    self?.showAlert(title: R.string.localizable.cameraDenied(),
                                    body: R.string.localizable.accessToCameraDenied())
                }
            }
        case .restricted, .denied:
            self.showAlert(
                title: R.string.localizable.cameraDenied(),
                body: R.string.localizable.accessToCameraDenied()
            )
        case .authorized: break
        @unknown default:
            logger.error("AVCaptureDevice authorizationStatus hit unknown case")
        }
    }

    func requestBluetoothPermission() {
        cbManager = CBCentralManager()
    }

    func showAlert(title: String, body: String) {
        alertTitle = title
        alertBody = body
        showAlert.toggle()
    }

    func checkForExistingSessionAndMoveToDashboard() {
        Task { @MainActor in
            if await getLastSessionIfExists() != nil {
                self.currentScreen = .dashboard // use `.demoDashboard` for mock dashboard
            }
        }
    }
}
