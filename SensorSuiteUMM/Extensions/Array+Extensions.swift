//
//  Array+Extensions.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 11/14/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Array {
    func unique<T: Hashable>(by: ((Element) -> (T))) -> [Element] { // swiftlint:disable:this identifier_name
        var set = Set<T>() // the unique list kept in a Set for fast retrieval
        var arrayOrdered = [Element]() // keeping the unique list of elements but ordered
        for value in self where !set.contains(by(value)) {
            set.insert(by(value))
            arrayOrdered.append(value)
        }

        return arrayOrdered
    }
}

extension Array where Element: BMMViewModel {
    func first(with id: String) -> BMMViewModel? {
        self.first(where: { $0.id.lowercased() == id.lowercased() })
    }
}
