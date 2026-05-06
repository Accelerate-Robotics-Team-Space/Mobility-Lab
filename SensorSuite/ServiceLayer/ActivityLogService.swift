//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol ActivityLogServiceProtocol: AnyObject {
    func setup(with sessionID: String?)
    func resume(with sessionID: String?)
}

extension Container {
    var activityLogService: Factory<ActivityLogServiceProtocol> {
        self { ActivityLogService() }.cached
    }
}

final class ActivityLogService: ActivityLogServiceProtocol {
    private let container: Container
    private let activityLogRepository: any ActivityLogRepositoryProtocol
    private let mqttService: MQTTServiceProtocol
    private let patientManager: PatientManagerProtocol
    private let userDefaults: BMMUserDefaultsServiceProtocol
    private let notificationCenter: NotificationCenterServiceProtocol

    private var sessionID: String?

    init(container: Container = .shared) {
        self.container = container
        self.activityLogRepository = container.activityLogRepository.resolve()
        self.mqttService = container.mqttService.resolve()
        self.patientManager = container.patientManager.resolve()
        self.userDefaults = container.userDefaults.resolve()
        self.notificationCenter = container.notificationCenter.resolve()

        self.notificationCenter.addObserver(
            self,
            selector: #selector(handleMQTTConnectionUpdate),
            name: MQTTService.statusNote,
            object: nil
        )
    }

    deinit {
        notificationCenter.removeObserver(self, name: MQTTService.statusNote)
    }

    func setup(with sessionID: String?) {
        guard let sessionID, sessionID != self.sessionID else {
            return
        }
        self.sessionID = sessionID
        Task {
            try? await self.activityLogRepository.deleteAll()
        }
    }

    func resume(with sessionID: String?) {
        Task {
            await activityLogRepository.endAllActivityLog()
        }
        self.sessionID = sessionID
    }

    private func syncActivities() {
         let bmmName: String = userDefaults.defaultingBaseStationFromApple
         GRDBStorageService.queue.async { [weak self, bmmName] in
             for var activity in (self?.getNotUploadedActivities() ?? []) {
                 self?.mqttService.publish(
                     activity.publishable(bmmName: bmmName).toData(),
                     to: activity.mqttTopicStr,
                     isRetained: false,
                     qos: .atLeastOnce
                 ) { [weak self] result in
                     activity.updateActivityLog(isSynced: result.isSuccess)
                     self?.activityLogRepository.syncSaveToDB(activity)
                 }
             }
             self?.patientManager.uploadPatientInfo()
         }
    }

    private func getNotUploadedActivities(limit: Int = 1000) -> [ALTActivityLog] {
        self.activityLogRepository.fetchNonSynced(withLimit: limit)
    }

    @objc
    private func handleMQTTConnectionUpdate() {
        if mqttService.status == .connected {
            syncActivities()
        }
    }
}
