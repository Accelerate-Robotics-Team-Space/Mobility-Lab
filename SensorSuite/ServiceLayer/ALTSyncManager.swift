//
//  ALTSyncManager.swift
//  SensorSuite
//
//  Created by Josh Franco on 3/10/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol SyncManagerProtocol: AnyObject {
    func startSync()
    func cleanup()
    func cleanup(result: ((Result<Int, Error>) -> Void)?)
}

extension SyncManagerProtocol {
    func cleanup() {
        cleanup(result: nil)
    }
}

extension Container {
    var syncManager: Factory<SyncManagerProtocol> {
        self { ALTSyncManager() }.cached
    }
}

final class ALTSyncManager: SyncManagerProtocol {
    private let logInterval: TimeInterval = 10
    private let syncBatchSize = 50
    private let syncQueue = DispatchQueue(label: "ALT_Synchronisation_Service", qos: .userInteractive)

    private var patientsLogCount: Int?
    private var activityLogCount: Int?

    // MARK: Services
    private let container: Container
    private let activityLogRepository: any ActivityLogRepositoryProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let notificationCenter: NotificationCenterServiceProtocol
    private let patientRepository: any PatientRepositoryProtocol
    private let securityService: SecurityServiceProtocol
    private let nodeManager: NodeManagerProtocol
    private let mqttService: MQTTServiceProtocol
    private let userDefaults: BMMUserDefaultsServiceProtocol

    private var isNetConnected: Bool {
        networkMonitor.isConnected
    }

    private var patientQueue: [ALTPatient] = []
    private var activityLogQueue: [ALTActivityLog] = []

    // MARK: - Init
    init(container: Container = .shared) {
        self.container = container
        self.activityLogRepository = container.activityLogRepository.resolve()
        self.networkMonitor = container.networkMonitor.resolve()
        self.notificationCenter = container.notificationCenter.resolve()
        self.patientRepository = container.patientRepository.resolve()
        self.securityService = container.securityService.resolve()
        self.nodeManager = container.nodeManager.resolve()
        self.mqttService = container.mqttService.resolve()
        self.userDefaults = container.userDefaults.resolve()

        notificationCenter.addObserver(self, selector: #selector(connectionHandler), name: NetworkMonitor.connectionNote, object: nil)
        logActivity()
    }

    // MARK: - Util
    func startSync() {
        syncQueue.async {
            self.beginSync()
        }
    }

    func cleanup() {
        cleanup(result: nil)
    }

    func cleanup(result: ((Result<Int, Error>) -> Void)?) {
        activityLogRepository.deleteAllFromDB(result: result)
    }
}

// MARK: - Private
private extension ALTSyncManager {
    @objc
    func connectionHandler() {
        syncQueue.async {
            self.beginSync()
        }
    }

    // MARK: Logging
    func logActivity() {
        if securityService.isDeviceRegistered {
            syncQueue.asyncAfter(deadline: .now() + logInterval) {
                var logStr = ""
                if let patientCount = self.patientsLogCount {
                    logStr += "\n Synced \(patientCount) Patients"
                    self.patientsLogCount = nil
                }

                if let activityLogAcount = self.activityLogCount {
                    logStr += "\n Synced \(activityLogAcount) Activity Logs"
                    self.activityLogCount = nil
                }

                if !logStr.isEmpty {
                    logStr += "\n"
                    logger.info(logStr)
                }

                self.logActivity()
            }
        }
    }

    // MARK: - Sync
    func beginSync() {
        dispatchAssertion(condition: .onQueue(syncQueue))
        if patientQueue.count < syncBatchSize {
            let delta = syncBatchSize - patientQueue.count
            let nonSyncedPatients = patientRepository.fetchNonSynced(withLimit: delta)
            self.patientQueue.insert(contentsOf: nonSyncedPatients, at: 0)
        }

        if !patientQueue.isEmpty {
            syncPatient {
                self.syncQueue.async { [weak self] in
                    guard let self else { return }

                    self.beginSync()
                }
            }
        }
    }

    func syncViaMesh(_ transmitter: MultipeerTransmitter, result: @escaping (Result<String, Error>) -> Void) {
        nodeManager.transmit(transmitter) { transmitResult in
            switch transmitResult {
            case .success:
                return result(.success("Transmitted via Mesh Network"))
            case .failure(let error):
                logger.error(error.localizedDescription)
                return result(.failure(error))
            }
        }
    }

    // MARK: Sync Patient
    func syncPatient(syncCount: Int = 0, completion: @escaping () -> Void) {
        guard let patient = patientQueue.popLast() else {
            self.patientsLogCount = (self.patientsLogCount ?? 0) + syncCount
            patientRepository.prune()
            return completion()
        }

        let syncResult: ((Result<String, Error>) -> Void) = { syncResult in
            self.syncQueue.async { [self] in
                switch syncResult {
                case .success(let resultStr):
					Task {
                        _ = await self.patientRepository.updateIsSynced(for: patient, to: true)
					}
                    self.syncPatient(syncCount: syncCount + 1, completion: completion)

                    if NetworkingConstants.showMQTTLogs {
                        logger.info(resultStr)
                    }
                case .failure(let error):
                    logger.error(error.localizedDescription)
                    self.patientQueue.removeAll()
                }
            }
        }

        switch (isNetConnected, mqttService.status == .connected) {
        case (false, _):    // Is not connected to internet, attempt to sync via mesh
            let transmitter = MultipeerTransmitter(
                topic: DataFeedTopics.patientInfo(facilityID: userDefaults.facilityId, baseStationGuid: userDefaults.baseStationGuid).structure,
                data: patient.publishable(turnProtocol: userDefaults.turnProtocol!, complianceAngle: userDefaults.complianceAngle!).toData(),
                isRetained: true,
                qosLvl: .atMostOnce
            )
            syncViaMesh(transmitter, result: syncResult)
        case (true, false): // Is connected but not connected to MQTT BE, attempt to connect to BE
            mqttService.executeOnConnection { [weak self] in
                self?.syncQueue.async {
                    self?.syncPatient(syncCount: syncCount, completion: completion)
                }
            }
        case (true, true):  // Is connected to both internet and MQTT BE, just publish the point
            mqttService.publish(
                patient.publishable(turnProtocol: userDefaults.turnProtocol!, complianceAngle: userDefaults.complianceAngle!).toData(),
                to: DataFeedTopics.patientInfo(facilityID: userDefaults.facilityId, baseStationGuid: userDefaults.baseStationGuid).structure,
                isRetained: true,
                qos: .atMostOnce,
                result: syncResult
            )
        }
    }
}
