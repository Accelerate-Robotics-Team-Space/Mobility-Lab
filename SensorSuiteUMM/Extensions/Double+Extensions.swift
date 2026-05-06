//
//  Double+Extensions.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/25/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Double {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

protocol Clampable: Numeric, Comparable, Sendable {
    func clamp() -> Self
    func clamp(to limits: ClosedRange<Self>) -> Self
}

extension Clampable {
    func clamp(to limits: ClosedRange<Self>) -> Self {
        min(max(limits.lowerBound, self), limits.upperBound)
    }
}

extension CGFloat: Clampable {
    func clamp() -> Self {
        clamp(to: (.zero ... .greatestFiniteMagnitude))
    }
}
extension Float: Clampable {
    func clamp() -> Self {
        clamp(to: (.zero ... .greatestFiniteMagnitude))
    }
}
extension Double: Clampable {
    func clamp() -> Self {
        clamp(to: (.zero ... .greatestFiniteMagnitude))
    }
}
extension Int: Clampable {
    func clamp() -> Self {
        clamp(to: (.zero ... .max))
    }
}
extension UInt: Clampable {
    func clamp() -> Self {
        clamp(to: (.zero ... .max))
    }
}
extension UInt8: Clampable {
    func clamp() -> Self {
        clamp(to: (.zero ... .max))
    }
}
extension Int8: Clampable {
    func clamp() -> Self {
        clamp(to: (.zero ... .max))
    }
}
extension UInt16: Clampable {
    func clamp() -> Self {
        clamp(to: (.zero ... .max))
    }
}
extension Int16: Clampable {
    func clamp() -> Self {
        clamp(to: (.zero ... .max))
    }
}
extension UInt32: Clampable {
    func clamp() -> Self {
        clamp(to: (.zero ... .max))
    }
}
extension Int32: Clampable {
    func clamp() -> Self {
        clamp(to: (.zero ... .max))
    }
}
extension Int64: Clampable {
    func clamp() -> Self {
        clamp(to: (.zero ... .max))
    }
}
extension UInt64: Clampable {
    func clamp() -> Self {
        clamp(to: (.zero ... .max))
    }
}
