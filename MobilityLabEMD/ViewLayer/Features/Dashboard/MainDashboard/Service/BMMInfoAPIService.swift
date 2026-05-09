//
//  BMMInfoAPIService.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 7/31/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol BMMInfoAPIServiceProtocol {
    func fetchBMMList(for deviceId: String) async throws -> [BMMStruct]
    func fetchBMMStatuses(for deviceId: String) async throws -> [BMMStatus]
    func fetchAnalytics(with data: AnalyticsRequestData) async throws -> AnalyticsResponse
}

extension Container {
    var bmmInfoAPIService: Factory<BMMInfoAPIServiceProtocol> {
        self { BMMInfoAPIService() }
            .cached
    }
}

class BMMInfoAPIService: BMMInfoAPIServiceProtocol {
    private let apiClient: AuthenticatedAPIClient<BMMInfoEndpoint>

    init(apiClient: AuthenticatedAPIClient<BMMInfoEndpoint> = .init()) {
        self.apiClient = apiClient
    }

    func fetchBMMList(for deviceId: String) async throws -> [BMMStruct] {
        try await apiClient.request(.getEMD(deviceId: deviceId))
    }

    func fetchBMMStatuses(for deviceId: String) async throws -> [BMMStatus] {
        try await apiClient.request(.getEMDReconnect(deviceId: deviceId))
    }

    func fetchAnalytics(with data: AnalyticsRequestData) async throws -> AnalyticsResponse {
        try await apiClient.request(.getAnalytics(data: data))
    }
}
