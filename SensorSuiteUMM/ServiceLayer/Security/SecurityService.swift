//
//  SecurityService.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import SwiftJWT

protocol SecurityServiceProtocol {
    func evaluateMeshCerts(_ certs: [Any]?, result: @escaping (Result<(), Error>) -> Void)
    func validateToken(_ jwtToken: String, result: @escaping (Result<(String, String), Error>) -> Void)
    func registerDevice(_ registration: DeviceRegistration, currentFacilityId: String, result: @escaping (Result<(SecKey), Error>) -> Void)

    func checkCertificateRevocationListIfNeeded()
    func checkCertificateRevocationList()

    func resetDeviceRegistered()
    func resetAll()

    var isDeviceRegistered: Bool { get }
}

extension Container {
    var securityService: Factory<SecurityServiceProtocol> {
        self { SecurityService.shared }.cached
    }
}

class SecurityService: SecurityServiceProtocol {
    static let shared: SecurityServiceProtocol = SecurityService()

    private var certificateRevocationListTimer: Timer?
    private var certificateRevocationListCheckInterval: TimeInterval = .secondsPerDay

    @Injected(\.keychain) private var keychain
    @Injected(\.notification) private var notificationService
    @Injected(\.userDefaults) private var userDefaults
    @Injected(\.provisioningAPIService)  private var provisioningService

    // MARK: - Computed Variables
    private lazy var jwtVerifier: JWTVerifier = {
        JWTVerifier.hs256(key: SecurityConstants.altSecret.toData())
    }()

    private lazy var jwtDecoder: JWTDecoder = {
        return JWTDecoder(jwtVerifier: jwtVerifier)
    }()
    
    var isDeviceRegistered: Bool {
        keychain.deviceCertificate != nil &&
        keychain.deviceCertificate?.serialNum != nil &&
        keychain.devicePublicKey != nil &&
        keychain.deviceCertIdentity != nil &&
        userDefaults.unitMobilityMonitorGuid != nil &&
        userDefaults.baseStationFromApple != nil &&
        userDefaults.facilityId != nil &&
        keychain.accessToken != nil
    }
    
    // MARK: - Init
    init() {
        checkDeviceAgainstCertificateRevocationList()
    }

    func validateToken(_ jwtToken: String, result: @escaping (Result<(String, String), Error>) -> Void) {
        do {
            let jwtValidation = try jwtDecoder.decode(JWT<ValidationClaims>.self, fromString: jwtToken)
            return result(.success((jwtValidation.claims.facility, jwtValidation.claims.host)))
        } catch {
            return result(.failure(error))
        }
    }
    
    func registerDevice(_ registration: DeviceRegistration, currentFacilityId: String, result: @escaping (Result<(SecKey), Error>) -> Void) {
        DispatchQueue.global(qos: .default).async {
            guard
                let identity = SecIdentity.constructor(p12Str: registration.certificate),
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

                    guard !self.isRevokedByCertificateRevocationList(serialNum) else {
                        return result(.failure(SecurityError.revokedByCrl))
                    }

                    self.keychain.deviceCertIdentity = identity
                    self.keychain.devicePublicKey = key
                    self.keychain.deviceIntermediateCert = intCert

                    self.userDefaults.unitMobilityMonitorGuid = registration.unitMobilityMonitorId
                    self.userDefaults.facilityId = currentFacilityId
                    self.userDefaults.facilityName = registration.facilityName

                    return result(.success(key))
                case .failure(let error):
                    return result(.failure(error))
                }
            }
        }
    }
    
    func resetDeviceRegistered() {
        userDefaults.reset()
        keychain.reset()
        HospitalRoomBed.deleteAllFromDB()
        HospitalUnit.deleteAllFromDB()
        
        notificationService.post(.revokedNote)
    }
    
    func resetTable() {
		do {
			try DataStore.shared.writer?.writeWithDeferredForeignKeys { store in
				try store.execute(sql: "DELETE FROM altActivityLog")
				try store.execute(sql: "DELETE FROM altPatient")
				try store.execute(sql: "DELETE FROM altSession")
			}
		} catch {
			logger.error(error.localizedDescription)
		}
    }
    
    func resetAll() {
		do {
			try DataStore.shared.writer?.writeWithDeferredForeignKeys { store in
				try store.execute(sql: "DELETE FROM hospitalRoomBed")
				try store.execute(sql: "DELETE FROM hospitalUnit")
				try store.execute(sql: "DELETE FROM revokedCertificate")
			}
			resetDeviceRegistered()
		} catch {
			logger.error(error.localizedDescription)
		}
    }

    func checkCertificateRevocationListIfNeeded() {
        let lastCheck = userDefaults.lastCertificateRevocationListCheck
        let nextCheck = lastCheck.addingTimeInterval(certificateRevocationListCheckInterval)
        let now = Date.now

        if now >= nextCheck {
            Task {
                let result = await getNewCertifiateRevocationList()
                switch result {
                case .success(let revokedCerts):
                    for var cert in revokedCerts {
                        cert.saveToDB()
                    }

                    self.checkDeviceAgainstCertificateRevocationList()
                case .failure(let error):
                    logger.error(error.localizedDescription)
                }

                userDefaults.lastCertificateRevocationListCheck = .now
                self.checkCertificateRevocationListIfNeeded()
            }
        } else if certificateRevocationListTimer == nil {
            let newTimer = Timer(fireAt: nextCheck,
                                 interval: 0, target: self,
                                 selector: #selector(certificateRevocationListTimerAction),
                                 userInfo: nil, repeats: false)

            certificateRevocationListTimer = newTimer
            RunLoop.main.add(newTimer, forMode: .common)
        }
    }

    func checkCertificateRevocationList() {
        Task {
            let result = await getNewCertifiateRevocationList()
            switch result {
            case .success(let revokedCerts):
                for var cert in revokedCerts {
                    cert.saveToDB()
                }
            case .failure(let error):
                logger.error(error.localizedDescription)
            }

            userDefaults.lastCertificateRevocationListCheck = .now
            self.checkDeviceAgainstCertificateRevocationList()
        }
    }
    
	func isSerialNumOnCertificateRevocationList(_ serialNum: String) -> Bool {
		RevokedCertificate.loadIdFromDB(serialNum) != nil
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

        guard !isSerialNumOnCertificateRevocationList(serialNum) else {
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
                return result(.failure(error))
            }
        }
    }
}

// MARK: - Private
private extension SecurityService {
    func getNewCertifiateRevocationList() async -> Result<[RevokedCertificate], Error> {
        guard let facilityId = UserDefaults.standard.facilityId else {
            return .failure(SecurityError.noFacilityId)
        }
        do {
            let jwtToken = try await provisioningService.getCertificateRevocationList(facilityId)
            let verified = try JWT<CertificateRevocationListClaims>(jwtString: jwtToken, verifier: self.jwtVerifier)
            let validation = verified.validateClaims(leeway: 15)

            switch validation {
            case .success:
                return .success(verified.claims.revokedCertificates)
            default:
                return .failure(SecurityError.someError(validation.description))
            }
        } catch {
            return .failure(error)
        }
    }
    
    func isRevokedByCertificateRevocationList(_ serialNum: String?) -> Bool {
        guard let serialNum = serialNum else { return false }
		return RevokedCertificate.loadIdFromDB(serialNum) != nil
    }
    
    func checkDeviceAgainstCertificateRevocationList() {
        guard
            let deviceSerialNum = keychain.deviceCertificate?.serialNum,
			let revokedCert = RevokedCertificate.loadIdFromDB(deviceSerialNum) else { return }
        
        resetDeviceRegistered()
        logger.error("Force Reset of Device due to revoked Cert: \(revokedCert)")
    }
    
    // MARK: - @objc Methods
    @objc
    func certificateRevocationListTimerAction() {
        certificateRevocationListTimer?.invalidate()
        certificateRevocationListTimer = nil
        checkCertificateRevocationListIfNeeded()
    }
}
