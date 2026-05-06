//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation
@testable import SensorSuite_BMM

final class MockProvisioningAPIService: ProvisioningAPIServiceProtocol {
    var crlHandler: ((String) -> AnyPublisher<String, any Error>)?
    var registerBaseStationPublisherHandler: ((String) -> AnyPublisher<DeviceRegistration, any Error>)?
    var getAvailableRoomBedHandler: ((String) -> AnyPublisher<[HospitalRoomBed], any Error>)?
    var getConfigHandler: ((String) -> AnyPublisher<FacilityConfig, any Error>)?
    var getUnitRoomsHandler: ((String?) -> AnyPublisher<UnitRoomModel, any Error>)?
    var checkIfUnitRoomsAddedHandler: ((String?) -> AnyPublisher<CheckUnitModel, any Error>)?
    var addOnePatchHandler: ((String, String, Int, String) async throws -> [String: Any])?
    var addNewPatientHandler: ((StartEndSessionModel) async throws -> [String: Any])?
    var endPatientSessionHandler: ((StartEndSessionModel) async throws -> [String: Any])?

    func getCertificateRevocationList(_ facilityId: String) -> AnyPublisher<String, any Error> {
        guard let crlHandler else {
            fatalError("crlHandler must be set")
        }
        return crlHandler(facilityId)
    }
    
    func registerBaseStationPublisher(id: String) -> AnyPublisher<DeviceRegistration, any Error> {
        guard let registerBaseStationPublisherHandler else {
            fatalError("registerBaseStationPublisherHandler must be set")
        }
        return registerBaseStationPublisherHandler(id)
    }
    
    func getAvailableRoomBed(_ facilityUnitId: String) -> AnyPublisher<[HospitalRoomBed], any Error> {
        guard let getAvailableRoomBedHandler else {
            fatalError("getAvailableRoomBedHandler must be set")
        }
        return getAvailableRoomBedHandler(facilityUnitId)
    }
    
    func getConfig(_ facilityId: String) -> AnyPublisher<FacilityConfig, any Error> {
        guard let getConfigHandler else {
            fatalError("getConfigHandler must be set")
        }
        return getConfigHandler(facilityId)
    }

    func getUnitRooms(_ dateAfter: String?) -> AnyPublisher<UnitRoomModel, any Error> {
        guard let getUnitRoomsHandler else {
            fatalError("getUnitRoomsHandler must be set")
        }
        return getUnitRoomsHandler(dateAfter)
    }
    
    func checkIfUnitRoomsAdded(_ dateAfter: String?) -> AnyPublisher<CheckUnitModel, any Error> {
        guard let checkIfUnitRoomsAddedHandler else {
            fatalError("checkIfUnitRoomsAddedHandler must be set")
        }
        return checkIfUnitRoomsAddedHandler(dateAfter)
    }

    func addOnePatch(_ facilityId: String, patientId: String, patchCount: Int, token: String) async throws -> [String: Any] {
        guard let addOnePatchHandler else {
            fatalError("addOnePatchHandler must be set")
        }
        return try await addOnePatchHandler(facilityId, patientId, patchCount, token)
    }

    func addNewPatient(_ details: StartEndSessionModel) async throws -> [String: Any] {
        guard let addNewPatientHandler else {
            fatalError("addNewPatientHandler must be set")
        }
        return try await addNewPatientHandler(details)
    }

    func endPatientSession(_ details: StartEndSessionModel) async throws -> [String: Any] {
        guard let endPatientSessionHandler else {
            fatalError("endPatientSessionHandler must be set")
        }
        return try await endPatientSessionHandler(details)
    }
}

final class NullProvisioningAPIService: ProvisioningAPIServiceProtocol {
    func getCertificateRevocationList(_ facilityId: String) -> AnyPublisher<String, any Error> {
        fatalError("Null Service Should Not Be Used")
    }

    func registerBaseStationPublisher(id: String) -> AnyPublisher<DeviceRegistration, any Error> {
        fatalError("Null Service Should Not Be Used")
    }

    func getAvailableRoomBed(_ facilityUnitId: String) -> AnyPublisher<[HospitalRoomBed], any Error> {
        fatalError("Null Service Should Not Be Used")
    }

    func addNewPatient(_ details: StartEndSessionModel) async throws -> [String: Any] {
        fatalError("Null Service Should Not Be Used")
    }

    func endPatientSession(_ details: StartEndSessionModel) async throws -> [String: Any] {
        fatalError("Null Service Should Not Be Used")
    }

    func getConfig(_ facilityId: String) -> AnyPublisher<FacilityConfig, any Error> {
        fatalError("Null Service Should Not Be Used")
    }

    func addOnePatch(_ facilityId: String, patientId: String, patchCount: Int, token: String) async throws -> [String: Any] {
        fatalError("Null Service Should Not Be Used")
    }

    func getUnitRooms(_ dateAfter: String?) -> AnyPublisher<UnitRoomModel, any Error> {
        fatalError("Null Service Should Not Be Used")
    }

    func checkIfUnitRoomsAdded(_ dateAfter: String?) -> AnyPublisher<CheckUnitModel, any Error> {
        fatalError("Null Service Should Not Be Used")
    }
}
