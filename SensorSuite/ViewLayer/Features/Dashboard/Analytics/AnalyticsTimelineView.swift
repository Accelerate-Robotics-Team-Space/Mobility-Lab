//
//  AnalyticsTimelineView.swift
//  SensorSuite BMM
//
//  Created by Vadym Riznychok on 7/23/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct AnalyticsTimelineView: View {
    var timeDivision: Int
    var blockDivision: Int
    var blockLenght: Int
    var isZoomed: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach((0...blockDivision), id: \.self) { vIndex in
                ZStack {
                    Rectangle()
                        .overlay(EdgeBorder(width: 1, edges: vIndex == blockDivision ? [.leading, .trailing] : [.leading])
                            .stroke(Color.charcoal4.opacity(0.3), lineWidth: 1))
                        .foregroundColor(.clear)
                    if isZoomed {
                        HStack {
                            Text(title(for: vIndex))
                                .font(.custom("Avenir-Roman", size: 12))
                                .foregroundColor(.charcoal4)
                                .padding(.leading, 4)
                            Spacer()
                        }
                    } else {
                        Text(title(for: vIndex))
                            .font(.custom("Avenir-Roman", size: 12))
                            .foregroundColor(.charcoal4)
                    }
                }
            }
        }
        .overlay(EdgeBorder(width: 1, edges: [.top, .bottom])
            .stroke(Color.charcoal4.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4])))
    }

    private func title(for index: Int) -> String {
        if isZoomed {
            return (index < 10 ? "0" : "") + "\(index)" + ":00"
        } else {
            return "\(blockLenght * (index + 1) - blockLenght)-\(blockLenght * (index + 1))h"
        }
    }
}

#Preview {
    AnalyticsTimelineView(timeDivision: 3, blockDivision: 3, blockLenght: 5, isZoomed: false)
}
