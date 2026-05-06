//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Collection {
    subscript (optional index: Index) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
