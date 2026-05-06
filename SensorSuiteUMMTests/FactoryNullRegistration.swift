//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
@testable import SensorSuite_UMM

extension Container {
    func resetAll() {
        Self.shared.reset()
        Self.shared.provisioningAPIService.register { NullProvisioningAPIService() }
        Self.shared.userDefaults.register { NullUserDefaultsService() }
        Self.shared.keychain.register { NullKeychainService() }
        Self.shared.notification.register { NullNotificationService() }
    }
}
