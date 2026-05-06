//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Date {
    static var referenceDate: Date {
        Date(timeIntervalSinceReferenceDate: 0)
    }

    static var twenty25: Date {
        Date(timeIntervalSinceReferenceDate: 757_382_400)
    }

    static func twenty25(plus: TimeInterval) -> Date {
        .twenty25.addingTimeInterval(plus)
    }

    func adding(_ interval: TimeInterval) -> Date {
        self.addingTimeInterval(interval)
    }
}
