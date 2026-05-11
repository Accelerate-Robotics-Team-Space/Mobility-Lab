//
//  ProvisioningAPIService.swift
//  MobilityLab BMM
//
//  Created by Vadym Riznychok on 7/31/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation

protocol ProvisioningAPIServiceProtocol {
    func registerEMD(deviceId: String) async throws -> DeviceRegistration
    func getCertificateRevocationList(_ facilityId: String) async throws -> String
    func getUnitRooms(_ dateAfter: String?) async throws -> UnitRoomModel
    func checkIfUnitRoomsAdded(_ dateAfter: String?) async throws -> CheckUnitModel
}

extension Container {
    var provisioningAPIService: Factory<ProvisioningAPIServiceProtocol> {
        self { ProvisioningAPIService() }
            .cached
    }
}

class ProvisioningAPIService: ProvisioningAPIServiceProtocol {
    private let apiClient: AuthenticatedAPIClient<ProvisioningEndpoint>

    init(apiClient: AuthenticatedAPIClient<ProvisioningEndpoint> = .init()) {
        self.apiClient = apiClient
    }

    func registerEMD(deviceId: String) async throws -> DeviceRegistration {
        try await apiClient.request(.registerEMD(deviceId: deviceId))
    }

    func getCertificateRevocationList(_ facilityId: String) async throws -> String {
        try await apiClient.request(.getCertificateRevocationList(facilityId: facilityId))
    }

    func getUnitRooms(_ dateAfter: String? = nil) async throws -> UnitRoomModel {
        try await apiClient.request(.getUnitRooms(dateAfter: dateAfter))
    }

    func checkIfUnitRoomsAdded(_ dateAfter: String? = nil) async throws -> CheckUnitModel {
        try await apiClient.request(.checkUnitRooms(dateAfter: dateAfter))
    }
}
