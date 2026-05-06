//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol UpdateServiceProtocol: AnyObject {
    @discardableResult func checkDidUpdateFromLastLaunch() -> Bool
    var isFirstLaunch: Bool { get }
}

extension Container {
    var updateService: Factory<UpdateServiceProtocol> {
        self { UpdateService() }.cached
    }
}

final class UpdateService: UpdateServiceProtocol {
    #if BMM
    @Injected(\.activityLogRepository) private var activityLogRepository
    #endif
    @Injected(\.userDefaults) private var userDefaults

    private(set) var didUpdateFromLastLaunch: Bool = false
    var isFirstLaunch: Bool = true

    @discardableResult
    func checkDidUpdateFromLastLaunch() -> Bool {
        guard let currentVersion = AppVersion(DeviceConstants.versionNumStr) else {
            assertionFailure("Could not parse App Version from \(DeviceConstants.versionNumStr)")
            logger.error("Could not parse App Version from \(DeviceConstants.versionNumStr)")
            return false
        }
        let lastVersion: AppVersion? = userDefaults.lastRunVersion
        self.isFirstLaunch = lastVersion == nil

        if let lastVersion {
            didUpdateFromLastLaunch = currentVersion > lastVersion
        } else {
            didUpdateFromLastLaunch = true
        }
        userDefaults.lastRunVersion = currentVersion

        // perform actions depending on updates
        switch (lastVersion, currentVersion) {
        case (nil, _):
            #if BMM
            if currentVersion >= .init(116) {
                // Prior versions of the app maintained the analytics logs in memory as they were added.
                // ALTActivityLogs were set to 'isSynced=TRUE' at the end of a session, not wiped.
                //
                // Versions since 1.0.117.0 show all analytics logs in DB. These are all deleted at the
                // end of a session.
                // Upgrades from older versions will incorrectly show old activityLogs,
                // and resume sessions based on old activityLogs.
                // Deleting activityLogs from older sessions will resolve this issue
                Task {
                    _ = try? await activityLogRepository.deleteAll()
                }
            }
            #else
            break
            #endif
        default:
            break
        }

        return didUpdateFromLastLaunch
    }
}
