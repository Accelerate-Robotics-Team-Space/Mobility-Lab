//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation

extension TimeInterval {
    var nSec: UInt64 {
        UInt64(self) * NSEC_PER_SEC
    }
}
