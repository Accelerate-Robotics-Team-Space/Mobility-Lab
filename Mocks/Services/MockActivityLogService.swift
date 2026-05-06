//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation
@testable import SensorSuite_BMM

final class MockActivityLogService: ActivityLogServiceProtocol {
    var setupHandler: ((String?) -> Void)?
    var resumeHandler: ((String?) -> Void)?

    func setup(with sessionID: String?) {
        guard let setupHandler else {
            fatalError("setupHandler not set")
        }
        setupHandler(sessionID)
    }
    
    func resume(with sessionID: String?) {
        guard let resumeHandler else {
            fatalError("resumeHandler not set")
        }
        resumeHandler(sessionID)
    }
}

final class NullActivityLogService: ActivityLogServiceProtocol {
    func setup(with sessionId: String?) {
        fatalError("Null Service Should Not Be Used")
    }

    func resume(with sessionId: String?) {
        fatalError("Null Service Should Not Be Used")
    }
}
