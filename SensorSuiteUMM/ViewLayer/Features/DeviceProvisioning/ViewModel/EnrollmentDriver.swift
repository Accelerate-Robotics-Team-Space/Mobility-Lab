//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import UIKit

@MainActor
class EnrollmentDriver: ObservableObject {
    @Injected(\.securityService)  private var securityService
    @Injected(\.provisioningAPIService) private var provisioningService

    @Published var isLoading = false
    @Published var showQrScanner = false
    @Published var deviceValidatedAndRegistered: Bool?
    @Published var showAlert = false {
        didSet {
            guard !showAlert else { return }
            enrollmentAlert = nil
        }
    }

    private let enrollmentType: EnrollmentType
    
    private var dismissAction: (() -> Void)?
    private var enrollmentAlert: EnrollmentAlert? {
        didSet {
            guard enrollmentAlert != nil else { return }
            showAlert.toggle()
        }
    }

    enum EnrollmentType {
        case device
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
        switch enrollmentType {
        case .device:
            R.string.localizable.enrollDevice()
        }
    }
    
    // MARK: - Init
    init(_ type: EnrollmentType) {
        self.enrollmentType = type
    }
    
    // MARK: - Util
    func scanHandler(result: Result<String, ScanError>) {
        switch result {
        case .success(let code):
            enroll(using: code)
        case .failure(let error):
            enrollmentAlert = .scan(err: error)
        }
    }
    
    func dismissObserver(completion: @escaping () -> Void) {
        dismissAction = completion
    }

    // MARK: - Enroll
    func enroll(using code: String) {
        guard isLoading == false else {
            logger.event("Cannot Enroll sensor, still waiting on last API call")
            return
        }

        securityService.validateToken(code) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success((facilityId, host)):
                UserDefaults.standard.host = host
                self.register(code, facilityId: facilityId)
            case .failure(let error):
                logger.error(error.localizedDescription)
                self.enrollmentAlert = .security(err: error)
            }
        }
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

    // MARK: - Registration
    func register(_ code: String, facilityId: String) {
        Keychain.shared.accessToken = code
        switch enrollmentType {
        case .device:
            Task {
                await registerDevice(probable: facilityId)
            }
        }
    }
    
    // MARK: Device Registration
    func registerDevice(probable facilityId: String) async {
        UserDefaults.standard.baseStationFromApple = UIDevice.current.identifierForVendor?.uuidString
        do {
            isLoading = true
            let registration = try await provisioningService.registerUMM(deviceId: DeviceConstants.deviceSerial)
            completeDeviceRegistration(registration, probableFacilityId: facilityId)
            isLoading = false
        } catch {
            isLoading = false
            logger.error(error.localizedDescription)
            self.enrollmentAlert = .rest(err: error)
            Keychain.shared.accessToken = nil
        }
    }
    
    func completeDeviceRegistration(
        _ registration: DeviceRegistration,
        probableFacilityId: String
    ) {
        let facilityConfigured = validateDeviceRegistration(registration)
        if facilityConfigured {
            securityService.registerDevice(registration, currentFacilityId: probableFacilityId) { deviceRegistered in
                switch deviceRegistered {
                case .success:
                    UserDefaults.standard.deviceRegistrationTime = DateFormatter.regDateFormatter.string(from: Date())
                    DispatchQueue.main.async { [weak self] in
                        self?.deviceValidatedAndRegistered = true
                    }
                case .failure(let error):
                    logger.error(error.localizedDescription)
                    DispatchQueue.main.async { [weak self] in
                        self?.deviceValidatedAndRegistered = false
                    }
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.deviceValidatedAndRegistered = false
            }
        }
    }
    
    func validateDeviceRegistration(_ registration: DeviceRegistration) -> Bool {
        var units = registration.units
        var rooms = registration.roomBeds

        // Remove units with no associated rooms
        units.removeAll { unit in
            return !rooms.contains(where: { $0.facilityUnitId == unit.id })
        }

        // Remove rooms not associated with units
        rooms.removeAll { room in
            return !units.contains(where: { $0.id == room.facilityUnitId })
        }

        for var unit in units {
            unit.saveToDB()
        }
        for var room in rooms {
            room.saveToDB()
        }

        if units.isEmpty || rooms.isEmpty {
            self.enrollmentAlert = .validation(action: {
                self.dismissAction?()
            })
        } else {
            self.dismissAction?()
            return true
        }
        
        return false
    }
}
