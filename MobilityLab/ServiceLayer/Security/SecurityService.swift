//
//  SecurityService.swift
//  MobilityLab
//
//  Created by Josh Franco on 10/28/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import SwiftJWT
import UIKit

protocol SecurityServiceProtocol: AnyObject {
    var isDeviceRegistered: Bool { get }
    func start()
    func updateDeviceId()
    func validateToken(_ jwtToken: String, result: @escaping (Result<(String, String), Error>) -> Void)
    func registerDevice(_ registration: DeviceRegistration, currentFacilityId: String, result: @escaping (Result<(), Error>) -> Void)
    func resetDeviceRegistered()
    func resetTable()
    func resetAll()
    func resetAllIsCurrent()
    func checkCertificateRevocationList()
    func isSerialNumOnCertificateRevocationList(_ serialNum: String) async -> Bool
    func evaluateMeshCerts(_ certs: [Any]?, result: @escaping (Result<(), Error>) -> Void)
}

extension Container {
    var securityService: Factory<SecurityServiceProtocol> {
        self { SecurityService() }.cached
    }
}

final class SecurityService: SecurityServiceProtocol {
    static let revokedNote = Notification.Name("Device-Registration-Revoked")

    private var certificateRevocationListCancellable: AnyCancellable?
    private var certificateRevocationListTimer: Timer?
    private var certificateRevocationListCheckInterval: TimeInterval = .secondsPerDay

    // MARK: Services
    private let container: Container
    @Injected(\.sentryLogger) private var sentryLogWriter
    @Injected(\.firebaseLogger) private var firebaseLogWriter
    @Injected(\.keychain) private var keychain
    @Injected(\.userDefaults) private var userDefaults
    @Injected(\.provisioningAPIService) private var provisioningAPIService
    @Injected(\.notificationCenter) private var notificationCenter
    private var syncManager: SyncManagerProtocol { container.syncManager.resolve() }
    private var mqttService: MQTTServiceProtocol { container.mqttService.resolve() }
    @Injected(\.activityLogRepository) private var activityLogRepository
    @Injected(\.databaseManagementService) private var databaseManagementService
    @Injected(\.patientRepository) private var patientRepository
    @Injected(\.hospitalUnitRepository) private var hospitalUnitRepository
    @Injected(\.hospitalRoomBedRepository) private var hospitalRoomBedRepository
    @Injected(\.revokedCertificateRepository) private var revokedCertificateRepository

    // MARK: - Computed Variables
    private lazy var jwtVerifier: JWTVerifier = {
        JWTVerifier.hs256(key: SecurityConstants.altSecret.toData())
    }()

    private lazy var jwtDecoder: JWTDecoder = {
        return JWTDecoder(jwtVerifier: jwtVerifier)
    }()

    var isDeviceRegistered: Bool {
        keychain.deviceCertificate != nil &&
        keychain.devicePublicKey != nil &&
        keychain.deviceCertificate?.serialNum != nil &&
        userDefaults.baseStationGuid != nil &&
        userDefaults.baseStationFromApple != nil &&
        userDefaults.facilityId != nil &&
        keychain.deviceCertIdentity != nil &&
        keychain.accessToken != nil
    }

    // MARK: - Init
    init(container: Container = .shared) {
        self.container = container
        checkDeviceAgainstCertificateRevocationList()
    }

    // MARK: - Util
    func start() {
        updateDeviceId()
        checkCertificateRevocationListIfNeeded()
    }

    func updateDeviceId() {
        if keychain.deviceId == nil {
            if let id = userDefaults.baseStationFromApple {
                keychain.deviceId = id
            } else {
                userDefaults.baseStationFromApple = UIDevice.current.identifierForVendor?.uuidString
                keychain.deviceId = UIDevice.current.identifierForVendor?.uuidString
            }
        }

        if userDefaults.baseStationFromApple != keychain.deviceId {
            let storedBaseStation = String(describing: userDefaults.baseStationFromApple)
            let storedDeviceId = String(describing: keychain.deviceId)
            logger.warn("BaseStationFromApple, Keychain mismatch: \(storedBaseStation) != \(storedDeviceId)")
            userDefaults.baseStationFromApple = keychain.deviceId
        }

        if let deviceID = userDefaults.baseStationFromApple {
            firebaseLogWriter.enrichWith(tags: ["deviceID": deviceID])
            sentryLogWriter.enrichWith(tags: ["bmm.deviceID": deviceID])
        }
    }

    func validateToken(_ jwtToken: String, result: @escaping (Result<(String, String), Error>) -> Void) {
        do {
            let jwtValidation = try jwtDecoder.decode(JWT<ValidationClaims>.self, fromString: jwtToken)
            return result(.success((jwtValidation.claims.facility, jwtValidation.claims.host)))
        } catch {
            logger.error(error.localizedDescription)
            return result(.failure(error))
        }
    }

    func registerDevice(
        _ registration: DeviceRegistration,
        currentFacilityId: String,
        result: @escaping (Result<(), Error>) -> Void
    ) {
        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let identity = SecIdentity.constructor(p12Str: registration.certificate),
                  let cert = identity.certificate,
                  let intCert = SecCertificate.constructor(x509Str: registration.intermediateCertificate),
                  let trust = SecTrust.constructor(from: [cert, intCert]) else {
                return result(.failure(SecurityError.unknown))
            }

            trust.evaluate { trustResult in
                switch trustResult {
                case .success(let key):
                    guard let serialNum = cert.serialNum else {
                        return result(.failure(SecurityError.noSerialNum))
                    }

                    Task {
                        guard await !(self?.isRevokedByCertificateRevocationList(serialNum) == true) else {
                            return result(.failure(SecurityError.revokedByCrl))
                        }

                        self?.keychain.deviceCertIdentity = identity
                        self?.keychain.devicePublicKey = key
                        self?.keychain.deviceIntermediateCert = intCert

                        self?.userDefaults.baseStationGuid = registration.baseStationId
                        self?.userDefaults.facilityId = currentFacilityId
                        self?.userDefaults.facilityName = registration.facilityName

                        return result(.success(()))
                    }
                case .failure(let error):
                    return result(.failure(error))
                }
            }
        }
    }

    func resetDeviceRegistered() {
        userDefaults.reset()
        keychain.reset()
        syncManager.cleanup()
        patientRepository.deleteAllFromDB()
        hospitalRoomBedRepository.deleteAllFromDB()
        hospitalUnitRepository.deleteAllFromDB()
        mqttService.reset()
        keychain.accessToken = nil
        notificationCenter.post(name: Self.revokedNote, object: nil)
    }

    func resetTable() {
        Task {
            do {
                try await databaseManagementService.resetTable()
            } catch {
                logger.error(error.localizedDescription)
            }
        }
    }

    func resetAll() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await databaseManagementService.resetAll()
                self.resetDeviceRegistered()
            } catch {
                logger.error(error.localizedDescription)
            }
        }
    }

    func resetAllIsCurrent() {
        Task {
            do {
                try await activityLogRepository.resetAllIsCurrent()
            } catch {
                logger.error(error.localizedDescription)
            }
        }
    }

    func checkCertificateRevocationList() {
        getNewCertificateRevocationList { [weak self] result in
            switch result {
            case .success(let revokedCerts):
                for cert in revokedCerts {
                    self?.revokedCertificateRepository.saveToDB(cert)
                }
            case .failure(let error):
                logger.error(error.localizedDescription)
            }

            self?.userDefaults.lastCertificateRevocationListCheck = .now
            self?.checkDeviceAgainstCertificateRevocationList()
        }
    }

    func isSerialNumOnCertificateRevocationList(_ serialNum: String) async -> Bool {
        await revokedCertificateRepository.loadIdFromDB(serialNum) != nil
    }

    func evaluateMeshCerts(_ certs: [Any]?, result: @escaping (Result<(), Error>) -> Void) {
        guard let certificate = certs, !certificate.isEmpty else {
            return result(.failure(SecurityError.noCerts))
        }

        // Only way to cast to SecCertificate is via a bang
        // swiftlint:disable:next force_cast
        let certArr = certificate.map({ $0 as! SecCertificate })
        guard let serialNum = certArr.first?.serialNum else {
            return result(.failure(SecurityError.noSerialNum))
        }

        Task { [weak self] in
            guard await !(self?.isSerialNumOnCertificateRevocationList(serialNum) == true) else {
                return result(.failure(SecurityError.revokedByCrl))
            }

            guard let trust = SecTrust.constructor(from: certArr) else {
                return result(.failure(SecurityError.badTrust))
            }

            trust.evaluate { evaluationResult in
                switch evaluationResult {
                case .success:
                    return result(.success)
                case .failure(let error):
                    logger.error(error.localizedDescription)
                    return result(.failure(error))
                }
            }
        }
    }
}

// MARK: - Private
private extension SecurityService {
    // MARK: - CRL
    func checkCertificateRevocationListIfNeeded() {
        let lastCheck = userDefaults.lastCertificateRevocationListCheck
        let nextCheck = lastCheck.addingTimeInterval(certificateRevocationListCheckInterval)
        let now = Date.now

        if now >= nextCheck {
            getNewCertificateRevocationList { [weak self] result in
                switch result {
                case .success(let revokedCerts):
                    for cert in revokedCerts {
                        self?.revokedCertificateRepository.saveToDB(cert)
                    }

                    self?.checkDeviceAgainstCertificateRevocationList()
                case .failure(let error):
                    logger.error(error.localizedDescription)
                }

                self?.userDefaults.lastCertificateRevocationListCheck = .now
                self?.checkCertificateRevocationListIfNeeded()
            }
        } else if certificateRevocationListTimer == nil {
            let newTimer = Timer(
                fireAt: nextCheck,
                interval: 0,
                target: self,
                selector: #selector(certificateRevocationListTimerAction),
                userInfo: nil,
                repeats: false
            )

            certificateRevocationListTimer = newTimer
            RunLoop.main.add(newTimer, forMode: .common)
        }
    }

    func getNewCertificateRevocationList(result: @escaping (Result<[RevokedCertificate], Error>) -> Void) {
        guard let facilityId = userDefaults.facilityId else {
            return result(.failure(SecurityError.noFacilityId))
        }
        certificateRevocationListCancellable = provisioningAPIService.getCertificateRevocationList(facilityId)
            .sink(receiveCompletion: { receiveResult in
                defer {
                    self.certificateRevocationListCancellable?.cancel()
                    self.certificateRevocationListCancellable = nil
                }

                switch receiveResult {
                case .finished: break
                case .failure(let error):
                    logger.error(error.localizedDescription)
                    return result(.failure(error))
                }
            }, receiveValue: { jwtToken in
                do {
                    let verified = try JWT<CertificateRevocationListClaims>(jwtString: jwtToken, verifier: self.jwtVerifier)
                    let validation = verified.validateClaims(leeway: 15)

                    switch validation {
                    case .success:
                        return result(.success(verified.claims.revokedCertificates))
                    default:
                        return result(.failure(SecurityError.someError(validation.description)))
                    }
                } catch {
                    logger.error(error.localizedDescription)
                    return result(.failure(error))
                }
            })
    }

    func isRevokedByCertificateRevocationList(_ serialNum: String?) async -> Bool {
        guard let serialNum else {
            return false
        }
        return await revokedCertificateRepository.loadIdFromDB(serialNum) != nil
    }

    func checkDeviceAgainstCertificateRevocationList() {
        guard
            let deviceSerialNum = keychain.deviceCertificate?.serialNum else { return }

        Task { [weak self] in
            guard let self = self else { return }
            self.revokedCertificateRepository.loadIdFromDB(deviceSerialNum) { completion in
                switch completion {
                case .success(let revokedCert):
                    if revokedCert != nil {
                        logger.error("Force Reset of Device due to revoked Cert: \(String(describing: revokedCert))")
                        self.resetDeviceRegistered()
                    }
                case .failure(let err):
                    logger.error(err.localizedDescription)
                }
            }
        }
    }

    // MARK: - @objc Methods
    @objc
    func certificateRevocationListTimerAction() {
        certificateRevocationListTimer?.invalidate()
        certificateRevocationListTimer = nil
        checkCertificateRevocationListIfNeeded()
    }
}
