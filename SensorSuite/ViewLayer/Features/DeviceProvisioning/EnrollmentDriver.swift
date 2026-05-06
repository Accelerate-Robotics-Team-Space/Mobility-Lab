//
//  EnrollmentDriver.swift
//  SensorSuite
//
//  Created by Josh Franco on 3/9/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import UIKit

final class EnrollmentDriver: ObservableObject {
    @Published var isLoading = false
    @Published var showQrScanner = false
    @Published var deviceValidatedAndRegistered: Bool?
    @Published var wearableRegistered: Bool?
    @Published var showAlert = false {
        didSet {
            guard !showAlert else { return }
            enrollmentAlert = nil
        }
    }

    // MARK: Services
    private let container: Container
    private let keychain: KeychainProtocol
    private let userDefaults: BMMUserDefaultsServiceProtocol
    private let securityService: SecurityServiceProtocol
    private let provisioningAPIService: ProvisioningAPIServiceProtocol
    private let mqttService: MQTTServiceProtocol
    private let hospitalRoomBedRepository: any HospitalRoomBedRepositoryProtocol
    private let hospitalUnitRepository: any HospitalUnitRepositoryProtocol

    private var dismissAction: (() -> Void)?
    private var wearableRegistration: WearableRegistration?
    private var enrollmentAlert: EnrollmentAlert? {
        didSet {
            guard enrollmentAlert != nil else { return }
            showAlert.toggle()
        }
    }
    
    private var registerTask: AnyCancellable? {
        didSet {
            isLoading = (registerTask != nil)
        }
    }

    init(container: Container = .shared) {
        self.container = container
        self.keychain = container.keychain.resolve()
        self.userDefaults = container.userDefaults.resolve()
        self.securityService = container.securityService.resolve()
        self.provisioningAPIService = container.provisioningAPIService.resolve()
        self.mqttService = container.mqttService.resolve()
        self.hospitalUnitRepository = container.hospitalUnitRepository.resolve()
        self.hospitalRoomBedRepository = container.hospitalRoomBedRepository.resolve()
    }

    // MARK: - Computed Variables
    var alertInfo: (String, String) {
        let title = enrollmentAlert?.title ?? R.string.localizable.none()
        let msg = enrollmentAlert?.description ?? R.string.localizable.unknown()
        
        return (title, msg)
    }
    
    var alertAction: () -> Void {
        enrollmentAlert?.action ?? {}
    }
    
    var title: String {
        return R.string.localizable.enrollDevice()
    }

    // MARK: - Util
    func scanHandler(result: Result<String, ScanError>) {
        switch result {
        case .success(let code):
			keychain.accessToken = code
            enroll(using: code)
        case .failure(let error):
            logger.error(error.localizedDescription)
            enrollmentAlert = .scan(err: error)
        }
    }
    
    func dismissObserver(completion: @escaping () -> Void) {
        dismissAction = completion
    }
}

// MARK: - Private
private extension EnrollmentDriver {
    enum EnrollmentAlert {
        case scan(err: Error)
        case rest(err: Error)
        case security(err: Error)
        case validation(action: () -> Void)
        
        var title: String {
            switch self {
            case .scan:
                return R.string.localizable.scannerErr()
            case .rest:
                return R.string.localizable.networkErr()
            case .security:
                return R.string.localizable.certErr()
            case .validation:
                return R.string.localizable.foundBadUnitsTitle()
            }
        }
        
        var description: String {
            switch self {
            case .scan(let err), .rest(let err), .security(let err):
                return err.localizedDescription
            case .validation:
                return R.string.localizable.foundBadUnits()
            }
        }
        
        var action: (() -> Void)? {
            switch self {
            case .validation(let action):
                return action
            default:
                return nil
            }
        }
    }
    
    // MARK: - Enroll
    func enroll(using code: String) {
        guard registerTask == nil else {
            logger.event("Cannot Enroll sensor, still waiting on last API call")
            return
        }
        
        securityService.validateToken(code) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success((facilityID, host)):
                userDefaults.host = host
                self.registerDevice(code, facilityID: facilityID)
            case .failure(let error):
                logger.error(error.localizedDescription)
                self.enrollmentAlert = .security(err: error)
            }
        }
    }
    
    // MARK: Device Registration
    func registerDevice(_ code: String, facilityID: String) {
        securityService.updateDeviceId()
        keychain.accessToken = code
        registerTask = provisioningAPIService
            .registerBaseStationPublisher(id: userDefaults.defaultingBaseStationFromApple)
            .sink(receiveCompletion: { [weak self] result in
                defer {
                    self?.registerTask = nil
                }
                
                switch result {
                case .finished: break
                case .failure(let error):
                    logger.error(error.localizedDescription)
                    self?.enrollmentAlert = .rest(err: error)
                    self?.keychain.accessToken = nil
                }
            }, receiveValue: { [weak self] registration in
                self?.completeDeviceRegistration(registration, facilityID: facilityID, code: code)
            })
    }
    
    func completeDeviceRegistration(_ registration: DeviceRegistration, facilityID: String, code: String) {
        let facilityConfigured = validateDeviceRegistration(registration)
        if facilityConfigured {
            self.securityService.registerDevice(registration, currentFacilityId: facilityID) { [weak self] deviceRegistered in
                switch deviceRegistered {
                case .success:
                    self?.userDefaults.deviceRegistrationTime = DateFormatter.regDateFormatter.string(from: Date())
                    DispatchQueue.main.async { [weak self] in
                        self?.mqttService.restartMQTTService()
                        self?.deviceValidatedAndRegistered = true
                    }
                case .failure(let error):
                    self?.keychain.accessToken = nil
                    logger.error(error.localizedDescription)
                    DispatchQueue.main.async { [weak self] in
                        self?.deviceValidatedAndRegistered = false
                    }
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.deviceValidatedAndRegistered = false
                self?.enrollmentAlert = .validation(action: {})
            }
        }
    }
    
    func validateDeviceRegistration(_ registration: DeviceRegistration) -> Bool {
        var units = registration.units
        let rooms = registration.roomBeds

        units.removeAll { unit in
            return !rooms.contains(where: { $0.facilityUnitId == unit.id })
        }

        for unit in units {
            hospitalUnitRepository.syncSaveToDB(unit) { result in
                if case .failure(let error) = result {
                    logger.error("Error saving Unit: \(error)")
                }
            }
        }
        
        for room in rooms where units.contains(where: { $0.id == room.facilityUnitId }) {
            hospitalRoomBedRepository.syncSaveToDB(room) { result in
                if case .failure(let error) = result {
                    logger.error("Error saving room: \(error)")
                }
            }
        }

        self.dismissAction?()
        return (!rooms.isEmpty && !units.isEmpty)
    }
}
