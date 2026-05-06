//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockUpdateService: UpdateServiceProtocol {
    var isFirstLaunchHandler: (() -> Bool)?
    var checkDidUpdateFromLastLaunchHandler: (() -> Bool)?

    func checkDidUpdateFromLastLaunch() -> Bool {
        guard let checkDidUpdateFromLastLaunchHandler else {
            fatalError("checkDidUpdateFromLastLaunchHandler must be set")
        }
        return checkDidUpdateFromLastLaunchHandler()
    }
    
    var isFirstLaunch: Bool {
        guard let isFirstLaunchHandler else {
            fatalError("isFirstLaunchHandler must be set")
        }
        return isFirstLaunchHandler()
    }
}

final class NullUpdateService: UpdateServiceProtocol {
    func checkDidUpdateFromLastLaunch() -> Bool {
        fatalError("Null Service Should Not Be Used")
    }
    
    var isFirstLaunch: Bool {
        fatalError("Null Service Should Not Be Used")
    }
}
