//
//  AnalyticsCumulativeDisplay.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 1/25/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct AnalyticsCumulativeDisplay: View {
    var title: String
    var totalTime: Int64
    var maxTime: Int64
    var partialTime: Int64
    var color: Color = .gray
    var totalTimeFormatted: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval((totalTime + partialTime) / 1000)) ?? "Unknown"
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 4)
                Text(title)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.charcoal1)
                Spacer().frame(height: 4)
                HStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: geo.size.width * 0.6 * min(CGFloat(totalTime) / CGFloat(maxTime), 1.0), height: 8)
                            .foregroundColor(color)
                        Rectangle()
                            .frame(width: geo.size.width * 0.6 * min(CGFloat(partialTime) / CGFloat(maxTime), 1.0), height: 8)
                            .foregroundColor(.yellow1)
                    }
                    .cornerRadius(4, corners: [.topLeft, .bottomLeft, .topRight, .bottomRight])
                    Spacer()
                        .frame(width: 8)
                    Text(totalTimeFormatted)
                        .font(.custom("Avenir-Roman", size: 14))
                        .foregroundColor(.charcoal3)
                }
                Spacer().frame(height: 4)
            }
        }
    }
}

struct AnalyticsCumulativeDisplay_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsCumulativeDisplay(title: R.string.localizable.leftLateral(),
                                   totalTime: 40000,
                                   maxTime: 86340,
                                   partialTime: 0,
                                   color: .indigo5)
        .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
