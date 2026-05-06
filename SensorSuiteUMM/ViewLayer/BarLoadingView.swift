//
//  BarLoadingView.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BarLoadingView: View {
    @State private var spacing = 15.0
    @State private var width = 150.0
    private var barColor: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            Capsule(style: .continuous)
                .fill(barColor)
                .frame(width: 10, height: 50)
            Capsule(style: .continuous)
                .fill(barColor)
                .frame(width: 10, height: 30)
            Capsule(style: .continuous)
                .fill(barColor)
                .frame(width: 10, height: 50)
            Capsule(style: .continuous)
                .fill(barColor)
                .frame(width: 10, height: 30)
            Capsule(style: .continuous)
                .fill(barColor)
                .frame(width: 10, height: 50)
        }
        .frame(width: width, alignment: .center)
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                spacing = 5
                width = 100
            }
        }
    }
    
    init(barColor: Color = .aqua) {
        self.barColor = barColor
    }
}

struct BarLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        BarLoadingView()
    }
}
