//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Int {
    static var secondsPerHour: Int { 3_600 }

    /// Seconds in a day, without considering leap seconds.
    /// The `Calendar` API should be used where accurate calculations are required
    static var secondsPerDay: Int { 86_400 }
}
