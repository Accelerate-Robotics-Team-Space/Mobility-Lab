//
//  AnalyticsDayView.swift
//  SensorSuite
//
//  Created by Vadym Riznychok on 5/15/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct AnalyticsDayView: View {
    var logs: [ActivityStartEnd]
    var timestamps: [TurnTimestamp]

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0, content: {
                    Spacer()
                        .frame(height: 11)
                        Text("Left lateral")
                            .font(.custom("Avenir-Roman", size: 12))
                            .foregroundColor(.charcoal1)
                    Spacer()
                        Text("Supine")
                            .font(.custom("Avenir-Roman", size: 12))
                            .foregroundColor(.charcoal1)
                    Spacer()
                        Text("Right lateral")
                            .font(.custom("Avenir-Roman", size: 12))
                            .foregroundColor(.charcoal1)
                    Spacer()
                    Text("Paused/Deficient")
                        .font(.custom("Avenir-Roman", size: 12))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text(" ")
                        .font(.custom("Avenir-Roman", size: 12))
                    Spacer()
                        .frame(height: 11)
                })
                .frame(width: 100, height: 183, alignment: .leading)
                AnalyticsChartView(logs: logs, timestamps: timestamps)
                    .frame(height: 183)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 12)
            AnalyticsNumberOfTurnsView(timestamps: timestamps)
                .background(Color.charcoal5.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.bottom, 19)
            HStack(spacing: 8) {
                Spacer()
                Stripes(config: StripesConfig(background: .green5, foreground: .green3.opacity(0.5),
                                              degrees: 45, barWidth: 1, barSpacing: 2))
                    .frame(width: 8, height: 8)
                Text("Expected Target")
                    .font(.custom("Avenir-Roman", size: 14))
                    .foregroundColor(Color(red: 0.047, green: 0.106, blue: 0.294))
                Spacer()
                    .frame(width: 8)
                Rectangle()
                    .fill(Color.red3)
                    .frame(width: 8, height: 8)
                Text("Non-Target/Deficient")
                    .font(.custom("Avenir-Roman", size: 14))
                    .foregroundColor(Color(red: 0.047, green: 0.106, blue: 0.294))
                Spacer()
                    .frame(width: 8)
                Rectangle()
                    .fill(Color.yellow1)
                    .frame(width: 8, height: 8)
                Text("Suboptimal")
                    .font(.custom("Avenir-Roman", size: 14))
                    .foregroundColor(Color(red: 0.047, green: 0.106, blue: 0.294))
                Spacer()
                    .frame(width: 8)
                Rectangle()
                    .fill(Color.charcoal3)
                    .frame(width: 8, height: 8)
                Text("Paused")
                    .font(.custom("Avenir-Roman", size: 14))
                    .foregroundColor(Color(red: 0.047, green: 0.106, blue: 0.294))
                Spacer()
            }
            .frame(height: 32)
            .frame(maxWidth: .infinity)
            .background(Color.charcoal5)
            .cornerRadius(8)
        }
        .padding(.leading, 26)
        .padding(.trailing, 22)
        .padding(.vertical)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 1)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct AnalyticsDayView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsDayView(logs: [], timestamps: [])
            .environmentObject(DashboardDriver())
            .frame(height: 200)
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
