//
//  ColorAnimation.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 11/17/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation
import SwiftUI

struct ColorAnimation: AnimatableModifier {
    var animatableData: Double
    let rgbaPair: [(Double, Double)]

    private static let garbage = [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]

    init(_ flag: Bool, from: Color, to: Color) {
        animatableData = flag ? 0 : 1
        guard let cc1 = UIColor(from).cgColor.components else {
            rgbaPair = Self.garbage
            return
        }
        guard let cc2 = UIColor(to).cgColor.components else {
            rgbaPair = Self.garbage
            return
        }
        rgbaPair = Array(zip(cc1.map(Double.init), cc2.map(Double.init)))
    }

    func body(content: Content) -> some View {
        content
            .foregroundColor(mixedColor)
    }

    // This is a very basic implementation of a color interpolation
    // between two values.
    var mixedColor: Color {
        let rgba = rgbaPair.map { $0.0 + ($0.1 - $0.0) * animatableData }
        return Color(red: rgba[0], green: rgba[1], blue: rgba[2], opacity: rgba[3])
    }
}
