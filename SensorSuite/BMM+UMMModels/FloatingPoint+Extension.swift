//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

extension FloatingPoint {
    init?(_ bytes: [UInt8]) {
        guard bytes.count == MemoryLayout<Self>.size else { return nil }
        self = bytes.withUnsafeBytes {
            return $0.load(fromByteOffset: 0, as: Self.self)
        }
    }
}
