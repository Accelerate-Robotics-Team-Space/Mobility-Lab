//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation

protocol ProvisioningAPIServiceProtocol: AnyObject {
    func getCertificateRevocationList(_ facilityId: String) -> AnyPublisher<String, Error>
    func registerBaseStationPublisher(id: String) -> AnyPublisher<DeviceRegistration, Error>
    func getAvailableRoomBed(_ facilityUnitId: String) -> AnyPublisher<[HospitalRoomBed], Error>
    func addNewPatient(_ details: StartEndSessionModel) async throws -> [String: Any]
    func endPatientSession(_ details: StartEndSessionModel) async throws -> [String: Any]
    func getConfig(_ facilityId: String) -> AnyPublisher<FacilityConfig, Error>
    func addOnePatch(_ facilityId: String, patientId: String, patchCount: Int, token: String) async throws -> [String: Any]
    func getUnitRooms(_ dateAfter: String?) -> AnyPublisher<UnitRoomModel, Error>
    func checkIfUnitRoomsAdded(_ dateAfter: String?) -> AnyPublisher<CheckUnitModel, Error>
}

extension Container {
    var provisioningAPIService: Factory<ProvisioningAPIServiceProtocol> {
        self { ProvisioningAPIService() }.cached
    }
}

final class ProvisioningAPIService: ProvisioningAPIServiceProtocol {
    private let apiClient: AuthenticatedAPIClient<ProvisioningEndpoint>

    init(apiClient: AuthenticatedAPIClient<ProvisioningEndpoint>? = nil) {
        self.apiClient = apiClient ?? .init()
    }

    func getCertificateRevocationList(_ facilityId: String) -> AnyPublisher<String, Error> {
        return apiClient.runForPlainText(.getCertificateRevocationList(facilityId: facilityId))
    }

    func registerBaseStationPublisher(id: String) -> AnyPublisher<DeviceRegistration, Error> {
        return apiClient.run(.registerBaseStation(deviceId: id))
    }

    func getAvailableRoomBed(_ facilityUnitId: String) -> AnyPublisher<[HospitalRoomBed], Error> {
        return apiClient.run(.getAvailableBed(facilityUnitId: facilityUnitId))
    }

    func addNewPatient(_ details: StartEndSessionModel) async throws -> [String: Any] {
        return try await apiClient.runRawAsync(.addPatient(details: details))
    }

    func endPatientSession(_ details: StartEndSessionModel) async throws -> [String: Any] {
        return try await apiClient.runRawAsync(.endSession(details: details))
    }

    func getConfig(_ facilityId: String) -> AnyPublisher<FacilityConfig, Error> {
        return apiClient.run(.getConfig(facilityId: facilityId))
    }

    func addOnePatch(_ facilityId: String, patientId: String, patchCount: Int, token: String) async throws -> [String: Any] {
        return try await apiClient.runRawAsync(.addPatch(facilityId: facilityId, patientId: patientId, count: patchCount, token: token))
    }

    func getUnitRooms(_ dateAfter: String? = nil) -> AnyPublisher<UnitRoomModel, Error> {
        return apiClient.run(.getUnitRooms(dateAfter: dateAfter))
    }

    func checkIfUnitRoomsAdded(_ dateAfter: String? = nil) -> AnyPublisher<CheckUnitModel, Error> {
        return apiClient.run(.checkUnitRooms(dateAfter: dateAfter))
    }
}
