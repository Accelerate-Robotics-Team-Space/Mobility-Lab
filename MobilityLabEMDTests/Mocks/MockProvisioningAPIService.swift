//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_EMD

final class MockProvisioningAPIService: ProvisioningAPIServiceProtocol {
    init() { }

    var registerEMDHandler: ((_ deviceID: String) -> Result<DeviceRegistration, Error>)?
    var getCRLHandler: (() -> Result<String, Error>)?
    var getUnitRoomsHandler: ((String?) -> UnitRoomModel)?
    var checkUnitRoomsAddedHandler: ((String?) async throws -> CheckUnitModel)?

    func registerEMD(deviceId: String) async throws -> DeviceRegistration {
        guard let registerEMDHandler else { fatalError("Register EMD Handler Must be Set") }
        switch registerEMDHandler(deviceId) {
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

    func registerEMD(deviceId: String) async throws -> DeviceRegistration {
        fatalError("Null Service Should Not Be Used")
    }

    func getCertificateRevocationList(_ facilityId: String) async throws -> String {
        fatalError("Null Service Should Not Be Used")
    }

    func getUnitRooms(_ dateAfter: String?) async throws -> MobilityLab_EMD.UnitRoomModel {
        fatalError("Null Service Should Not Be Used")
    }

    func checkIfUnitRoomsAdded(_ dateAfter: String?) async throws -> MobilityLab_EMD.CheckUnitModel {
        fatalError("Null Service Should Not Be Used")
    }
}
