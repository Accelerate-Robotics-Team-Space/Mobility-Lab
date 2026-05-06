//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
@testable import SensorSuite_BMM

extension Container {
    func resetAll() {
        reset()
        activityLogService.register { NullActivityLogService() }
        audioPlayer.register { NullAudioPlayer() }
        consoleLogRepository.register { NullConsoleLogRepository() }
        databaseManagementService.register { NullDatabaseManagementService() }
        errorLogRepository.register { NullErrorLogRepository() }
        firebaseLogger.register { NullFirebaseLogger() }
        hospitalRoomBedRepository.register { NullHospitalRoomBedRepository() }
        hospitalUnitRepository.register { NullHospitalUnitRepository() }
        keychain.register { NullKeychain() }
        mqttService.register { NullMQTTService() }
        networkMonitor.register { NullNetworkMonitor() }
        nodeManager.register { NullNodeManager() }
        notificationCenter.register { NullNotificationCenterService() }
        patchTrackingService.register { NullPatchTrackingService() }
        patientManager.register { NullPatientManager() }
        patientRepository.register { NullPatientRepository() }
        provisioningAPIService.register { NullProvisioningAPIService() }
        revokedCertificateRepository.register { NullRevokedCertificateRepository() }
        securityService.register { NullSecurityService() }
        sentryLogger.register { NullSentryLogger() }
        sessionRepository.register { NullSessionRepository() }
        syncManager.register { NullSyncManager() }
        userDefaults.register { NullUserDefaultsService() }
        rollCompliance.register { NullRollCompliance() }
        updateService.register { NullUpdateService() }
    }
}
