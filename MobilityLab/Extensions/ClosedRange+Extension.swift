//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//

import Foundation

extension ClosedRange where Bound: SignedNumeric {

    /// Negates a numeric range.
    ///
    /// 1. `(3...6)` becomes `(-6...-3)`
    /// 2. `(-50...-1)` becomes `(1...50)`
    ///
    /// Or in mathematical notation:\
    /// 3. `[1, 20]` becomes `[-20, -1]`
    /// - returns: The negated version of a range.
    func negated() -> Self {
        (-upperBound)...(-lowerBound)
    }
}
