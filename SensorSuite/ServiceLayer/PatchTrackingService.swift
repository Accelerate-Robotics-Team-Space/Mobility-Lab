//
//  PatchTrackingService.swift
//  SensorSuite BMM
//
//  Created by Vadym Riznychok on 6/26/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol PatchTrackingServiceProtocol {
    func patchUsed()
}

extension Container {
    var patchTrackingService: Factory<PatchTrackingServiceProtocol> {
        self { PatchTrackingService() }.cached
    }
}

final class PatchTrackingService: PatchTrackingServiceProtocol {
    private var isLoading = false

    // MARK: Services
    private let container: Container
    private let keychain: KeychainProtocol
    private let provisioningAPIService: ProvisioningAPIServiceProtocol
    private let patientManager: PatientManagerProtocol
    private let userDefaults: BMMUserDefaultsServiceProtocol
    private let notificationCenter: NotificationCenterServiceProtocol

    init(container: Container = .shared) {
        self.container = container
        self.keychain = container.keychain.resolve()
        self.provisioningAPIService = container.provisioningAPIService.resolve()
        self.patientManager = container.patientManager.resolve()
        self.userDefaults = container.userDefaults.resolve()
        self.notificationCenter = container.notificationCenter.resolve()

        notificationCenter.addObserver(
            self,
            selector: #selector(connectionHandler),
            name: NetworkMonitor.connectionNote,
            object: nil
        )
    }

    func patchUsed() {
        userDefaults.unsyncedPatchCount += 1
        Task {
            await syncPatchCount()
        }
    }

    private func syncPatchCount() async {
        guard userDefaults.unsyncedPatchCount > 0, isLoading == false else { return }

        let facilityId = patientManager.patientLocation?.unit.facilityId
        let patientId = patientManager.currentPatient?.altPatientId

        if let facilityId, let patientId, let token = keychain.accessToken {
            isLoading = true
            do {
                _ = try await provisioningAPIService.addOnePatch(
                    facilityId,
                    patientId: patientId,
                    patchCount: userDefaults.unsyncedPatchCount,
                    token: token
                )
                userDefaults.unsyncedPatchCount = 0
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }

    @objc
    private func connectionHandler() {
        Task {
            await syncPatchCount()
        }
    }
}
