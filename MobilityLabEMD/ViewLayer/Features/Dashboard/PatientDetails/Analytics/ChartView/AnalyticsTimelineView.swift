//
//  AnalyticsTimelineView.swift
//  MobilityLab BMM
//
//  Created by Vadym Riznychok on 7/23/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct AnalyticsTimelineView: View {
    var timeDivision: Int
    var turnHours: Int
    var isZoomed: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach((0...timeDivision), id: \.self) { vIndex in
                ZStack {
                    Rectangle()
                        .overlay(EdgeBorder(width: 1, edges: vIndex == timeDivision ? [.leading, .trailing] : [.leading])
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
            return hour(for: index) + "-" + hour(for: index + 1)
        }
    }

    private func hour(for index: Int) -> String {
        let hour = index * turnHours
        return (hour < 10 ? "0" : "") + "\(hour)"
    }
}

#Preview {
    AnalyticsTimelineView(timeDivision: 3, turnHours: 3, isZoomed: false)
}
