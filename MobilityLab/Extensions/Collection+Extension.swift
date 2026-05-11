//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Collection {
    /// Ensures that all items in the array satisfy the corresponding range in ranges array.
    /// > Each value is tested against the range at the same index.
    ///
    /// - Parameters:
    ///   - ranges: An array of ranges that is the same length as the original array.
    /// - Returns: `true` if each value falls within the range at the same index
    func all<U: RangeExpression>(in ranges: [U]) -> Bool where U.Bound == Element {
        zip(ranges, self).allSatisfy(~=)
    }
}

struct Diffs<T: Equatable & Identifiable> {
    var new: [T]
    var updated: [T]
    var unchanged: [T]
    var removed: [T]

    init(new: [T], updated: [T], unchanged: [T], removed: [T]) {
        self.new = new
        self.updated = updated
        self.unchanged = unchanged
        self.removed = removed
    }

    init() {
        self.new = []
        self.updated = []
        self.unchanged = []
        self.removed = []
    }

    /// new + updated + unchanged
    var retained: [T] {
        new + updated + unchanged
    }

    /// new + updated
    var newAndUpdated: [T] {
        new + updated
    }

    /// new + updated + unchanged + removed
    var all: [T] {
        new + updated + unchanged + removed
    }

    /// updated + removed
    var updatedAndRemoved: [T] {
        updated + removed
    }
}

extension Collection where Element: Equatable, Element: Identifiable {
    func diffWith(existing: [Element]) -> Diffs<Element> {
        let existingIDs = Set(existing.map(\.id))
        var diff = self.reduce(into: Diffs<Element>()) { accumulator, item in
            if existingIDs.contains(item.id) {
                if let existingItem = existing.first(where: { $0.id == item.id }), existingItem == item {
                    accumulator.unchanged.append(item)
                } else {
                    accumulator.updated.append(item)
                }
            } else {
                accumulator.new.append(item)
            }
        }
        let retainedIDs = Set(diff.retained.map(\.id))
        let deleteIDs = existingIDs.subtracting(retainedIDs)
        diff.removed = existing.filter { deleteIDs.contains($0.id) }
        return diff
    }
}
