//
//  ProgressBar.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 11/2/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ProgressBar: View {
    var value: Double
    var isPaused: Bool

    var color: Color {
        if value < 0.5 {
            return .red1
        } else if value < 0.79 {
            return .yellow1
        } else {
            return .green1
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geo.size.width, height: geo.size.height)
                    .foregroundColor(.charcoal5)
                
                Rectangle().frame(width: CGFloat(self.value) * geo.size.width, height: geo.size.height)
                    .foregroundColor(isPaused ? .charcoal3 : color)
                    .cornerRadius(2000, corners: [.topRight, .bottomRight])
            }
        }
    }
}

#Preview {
    ProgressBar(value: 0.5, isPaused: true)
        .frame(height: 8)
        .padding()
}
