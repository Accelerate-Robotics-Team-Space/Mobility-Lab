//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM

final class MockPatchTrackingService: PatchTrackingServiceProtocol {
    var patchUsedHandler: (() -> Void)?

    func patchUsed() {
        guard let patchUsedHandler else {
            fatalError("patchUsedHandler must be set")
        }
        patchUsedHandler()
    }
}

final class NullPatchTrackingService: PatchTrackingServiceProtocol {
    func patchUsed() {
        fatalError("Null Service Should Not Be Used")
    }
}
