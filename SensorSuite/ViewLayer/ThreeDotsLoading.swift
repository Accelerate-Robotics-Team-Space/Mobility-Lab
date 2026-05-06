//
//  ThreeDotsLoading.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 10/19/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ThreeDotsLoading: View {
    var body: some View {
        HStack(spacing: 2) {
            SingleDotShape()
            SingleDotShape(delay: 0.2)
            SingleDotShape(delay: 0.3)
        }
    }
}

struct ThreeDotsLoading_Previews: PreviewProvider {
    static var previews: some View {
        ThreeDotsLoading()
    }
}
