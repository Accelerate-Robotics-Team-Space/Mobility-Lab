//
//  Sequence+Extensions.swift
//  MobilityLab EMD
//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//
import Foundation

public extension Sequence {
    func displaySorted(by keyPath: KeyPath<Self.Element, String>,
                       using comparator: ComparisonResult = .orderedAscending) -> [Self.Element] {
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
