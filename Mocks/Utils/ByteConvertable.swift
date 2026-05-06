// swiftlint:disable:this file_name
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation

protocol ByteConvertible { }

extension ByteConvertible {
    func toBytes() -> [UInt8] {
        var mutableValue = self
        let size = MemoryLayout<Self>.size
        return withUnsafePointer(to: &mutableValue) {
            $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                Array(UnsafeBufferPointer(start: $0, count: size))
            }
        }
    }
}

extension Double: ByteConvertible { }
extension Int64: ByteConvertible { }
