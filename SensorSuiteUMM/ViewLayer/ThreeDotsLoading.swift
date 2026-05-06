//
//  ThreeDotsLoading.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/28/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ThreeDotsLoading: View {
    var body: some View {
        HStack(spacing: 2) {
            SingleDotShape(delay: 0.1)
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
