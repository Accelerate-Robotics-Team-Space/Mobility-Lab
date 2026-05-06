//
//  Binding+Extensions.swift
//  SensorSuite
//
//  Created by Vadym Riznychok on 5/11/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

extension Binding {
     func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
