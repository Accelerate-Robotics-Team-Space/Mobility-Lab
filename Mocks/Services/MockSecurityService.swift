//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockSecurityService: SecurityServiceProtocol {
    var isDeviceRegisteredHandler: (() -> Bool)?
    var startHandler: (() -> Void)?
    var updateDeviceIdHandler: (() -> Void)?
    var validateTokenHandler: ((String, (Result<(String, String), any Error>) -> Void) -> Void)?
    var registerDeviceHandler: ((DeviceRegistration, String, (Result<(), any Error>) -> Void) -> Void)?
    var resetDeviceRegisteredHandler: (() -> Void)?
    var resetTableHandler: (() -> Void)?
    var resetAllHandler: (() -> Void)?
    var resetAllIsCurrentHandler: (() -> Void)?
    var checkCertificateRevocationListHandler: (() -> Void)?
    var isSerialNumOnCertificateRevocationListHandler: ((String) async -> Bool)? // swiftlint:disable:this identifier_name
    var evaluateMeshCertsHandler: (([Any]?, (Result<(), any Error>) -> Void) -> Void)?

    var isDeviceRegistered: Bool {
        guard let isDeviceRegisteredHandler else {
            fatalError("isDeviceRegisteredHandler must be set")
        }
        return isDeviceRegisteredHandler()
    }

    func start() {
        guard let startHandler else {
            fatalError("startHandler must be set")
        }
        startHandler()
    }
    
    func updateDeviceId() {
        guard let updateDeviceIdHandler else {
            fatalError("updateDeviceIdHandler must be set")
        }
        updateDeviceIdHandler()
    }
    
    func validateToken(_ jwtToken: String, result: @escaping (Result<(String, String), any Error>) -> Void) {
        guard let validateTokenHandler else {
            fatalError("validateTokenHandler must be set")
        }
        validateTokenHandler(jwtToken, result)
    }
    
    func registerDevice(_ registration: DeviceRegistration, currentFacilityId: String, result: @escaping (Result<(), any Error>) -> Void) {
        guard let registerDeviceHandler else {
            fatalError("registerDeviceHandler must be set")
        }
        registerDeviceHandler(registration, currentFacilityId, result)
    }
    
    func resetDeviceRegistered() {
        guard let resetDeviceRegisteredHandler else {
            fatalError("resetDeviceRegisteredHandler must be set")
        }
        resetDeviceRegisteredHandler()
    }
    
    func resetTable() {
        guard let resetTableHandler else {
            fatalError("resetTableHandler must be set")
        }
        resetTableHandler()
    }
    
    func resetAll() {
        guard let resetAllHandler else {
            fatalError("resetAllHandler must be set")
        }
        resetAllHandler()
    }
    
    func resetAllIsCurrent() {
        guard let resetAllIsCurrentHandler else {
            fatalError("resetAllIsCurrentHandler must be set")
        }
        resetAllIsCurrentHandler()
    }
    
    func checkCertificateRevocationList() {
        guard let checkCertificateRevocationListHandler else {
            fatalError("checkCertificateRevocationListHandler must be set")
        }
        checkCertificateRevocationListHandler()
    }
    
    func isSerialNumOnCertificateRevocationList(_ serialNum: String) async -> Bool {
        guard let handler = isSerialNumOnCertificateRevocationListHandler else {
            fatalError("isSerialNumOnCertificateRevocationListHandler must be set")
        }
        return await handler(serialNum)
    }
    
    func evaluateMeshCerts(_ certs: [Any]?, result: @escaping (Result<(), any Error>) -> Void) {
        guard let evaluateMeshCertsHandler else {
            fatalError("evaluateMeshCertsHandler must be set")
        }
        evaluateMeshCertsHandler(certs, result)
    }
}

final class NullSecurityService: SecurityServiceProtocol {
    var isDeviceRegistered: Bool {
        fatalError("Null Service Should Not Be Used")
    }

    func start() {
        fatalError("Null Service Should Not Be Used")
    }

    func updateDeviceId() {
        fatalError("Null Service Should Not Be Used")
    }

    func validateToken(_ jwtToken: String, result: @escaping (Result<(String, String), any Error>) -> Void) {
        fatalError("Null Service Should Not Be Used")
    }

    func registerDevice(_ registration: DeviceRegistration, currentFacilityId: String, result: @escaping (Result<(), any Error>) -> Void) {
        fatalError("Null Service Should Not Be Used")
    }

    func resetDeviceRegistered() {
        fatalError("Null Service Should Not Be Used")
    }

    func resetTable() {
        fatalError("Null Service Should Not Be Used")
    }

    func resetAll() {
        fatalError("Null Service Should Not Be Used")
    }

    func resetAllIsCurrent() {
        fatalError("Null Service Should Not Be Used")
    }

    func checkCertificateRevocationList() {
        fatalError("Null Service Should Not Be Used")
    }

    func isSerialNumOnCertificateRevocationList(_ serialNum: String) async -> Bool {
        fatalError("Null Service Should Not Be Used")
    }

    func evaluateMeshCerts(_ certs: [Any]?, result: @escaping (Result<(), any Error>) -> Void) {
        fatalError("Null Service Should Not Be Used")
    }
}
