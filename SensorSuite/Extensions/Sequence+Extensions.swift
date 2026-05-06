//
//  Sequence+Extensions.swift
//  SensorSuite
//
//  Created by Josh Franco on 12/29/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

// MARK: - Hashable
extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - PositionalFlags
extension Sequence where Iterator.Element == PositionalFlags {
    func combine() -> Iterator.Element {
        PositionalFlags(rawValue: Set(self.map(\.rawValue)).reduce(0, +))
    }
}

public extension Sequence {
    func displaySorted(
        by keyPath: KeyPath<Self.Element, String>,
        using comparator: ComparisonResult = .orderedAscending
    ) -> [Self.Element] {
        sorted(by: { $0[keyPath: keyPath].localizedStandardCompare($1[keyPath: keyPath]) == comparator })
    }

    func displaySorted(
        by keyPath: KeyPath<Self.Element, String?>,
        fallback fallbackKeyPath: KeyPath<Self.Element, String>,
        using comparator: ComparisonResult = .orderedAscending
    ) -> [Self.Element] {
        sorted(by: {
            if let left = $0[keyPath: keyPath], let right = $1[keyPath: keyPath] {
                return left.localizedStandardCompare(right) == comparator
            } else {
                return $0[keyPath: fallbackKeyPath].localizedStandardCompare($1[keyPath: fallbackKeyPath]) == comparator
            }
        })
    }
}
