//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_UMM

final class MockProvisioningAPIService: ProvisioningAPIServiceProtocol {
    init() { }

    var registerUMMHandler: ((_ deviceID: String) -> Result<DeviceRegistration, Error>)?
    var getCRLHandler: (() -> Result<String, Error>)?
    var getUnitRoomsHandler: ((String?) -> UnitRoomModel)?
    var checkUnitRoomsAddedHandler: ((String?) async throws -> CheckUnitModel)?

    func registerUMM(deviceId: String) async throws -> DeviceRegistration {
        guard let registerUMMHandler else { fatalError("Register UMM Handler Must be Set") }
        switch registerUMMHandler(deviceId) {
        case .success(let registration):
            return registration
        case .failure(let error):
            throw error
        }
    }

    func getCertificateRevocationList(_ facilityId: String) async throws -> String {
        guard let getCRLHandler else { fatalError("Get CRL Handler Must be Set") }
        switch getCRLHandler() {
        case .success(let crl):
            return crl
        case .failure(let error):
            throw error
        }
    }

    func getUnitRooms(_ dateAfter: String?) async throws -> UnitRoomModel {
        guard let getUnitRoomsHandler else {
            fatalError("Get Unit Rooms Handler Must be Set")
        }
        return try await getUnitRoomsHandler(dateAfter)
    }

    func checkIfUnitRoomsAdded(_ dateAfter: String?) async throws -> CheckUnitModel {
        guard let checkUnitRoomsAddedHandler else {
            fatalError("checkUnitRoomsAddedHandler must be set")
        }
        return try await checkUnitRoomsAddedHandler(dateAfter)
    }
}

final class NullProvisioningAPIService: ProvisioningAPIServiceProtocol {
    init() { }

    func registerUMM(deviceId: String) async throws -> DeviceRegistration {
        fatalError("Null Service Should Not Be Used")
    }

    func getCertificateRevocationList(_ facilityId: String) async throws -> String {
        fatalError("Null Service Should Not Be Used")
    }

    func getUnitRooms(_ dateAfter: String?) async throws -> SensorSuite_UMM.UnitRoomModel {
        fatalError("Null Service Should Not Be Used")
    }

    func checkIfUnitRoomsAdded(_ dateAfter: String?) async throws -> SensorSuite_UMM.CheckUnitModel {
        fatalError("Null Service Should Not Be Used")
    }
}
