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

    var body: some View {
        GeometryReader { geo in
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 0, content: {
                        Text("Left lateral")
                            .font(.custom("Avenir-Roman", size: 12))
                            .foregroundColor(.charcoal1)
                            .frame(maxHeight: .infinity)
                        Text("Supine")
                            .font(.custom("Avenir-Roman", size: 12))
                            .foregroundColor(.charcoal1)
                            .frame(maxHeight: .infinity)
                        Text("Right lateral")
                            .font(.custom("Avenir-Roman", size: 12))
                            .foregroundColor(.charcoal1)
                            .frame(maxHeight: .infinity)
                        Text("Paused /\nDeficient")
                            .font(.custom("Avenir-Roman", size: 12))
                            .foregroundColor(.charcoal1)
                            .frame(maxHeight: .infinity)
                        Text(" ")
                            .font(.custom("Avenir-Roman", size: 12))
                            .frame(maxHeight: .infinity)
                    })
                    .frame(width: 90)
                    AnalyticsChartView(logs: logs)
                        .frame(height: geo.size.width * 0.389)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing)
                .padding(.leading, 8)
                .padding(.bottom, 24)
                HStack(spacing: 6) {
                    VStack {
                        HStack(spacing: 12) {
                            Spacer()
                            Stripes(config: StripesConfig(background: .green5, foreground: .green3.opacity(0.5),
                                                          degrees: 45, barWidth: 1, barSpacing: 2))
                            .frame(width: 8, height: 8)
                            Text("Expected Target")
                                .font(.custom("Avenir-Roman", size: 14))
                                .foregroundColor(Color(red: 0.047, green: 0.106, blue: 0.294))
                            Spacer()
                                .frame(width: 4)
                            Rectangle()
                                .fill(Color.red3)
                                .frame(width: 8, height: 8)
                            HStack(spacing: 0) {
                                Text("Non-Target")
                                    .font(.custom("Avenir-Roman", size: 14))
                                    .foregroundColor(Color(red: 0.047, green: 0.106, blue: 0.294))
                                Text("/")
                                    .font(.custom("Avenir-Roman", size: 14))
                                    .bold()
                                    .foregroundColor(Color(red: 0.047, green: 0.106, blue: 0.294))
                                Text("Deficient")
                                    .font(.custom("Avenir-Roman", size: 14))
                                    .foregroundColor(Color(red: 0.047, green: 0.106, blue: 0.294))
                            }
                            Spacer()
                        }
                        HStack(spacing: 12) {
                            Spacer()
                            Rectangle()
                                .fill(Color.yellow1)
                                .frame(width: 8, height: 8)
                            Text("Suboptimal")
                                .font(.custom("Avenir-Roman", size: 14))
                                .foregroundColor(Color(red: 0.047, green: 0.106, blue: 0.294))
                            Spacer()
                                .frame(width: 4)
                            Rectangle()
                                .fill(Color.charcoal3)
                                .frame(width: 8, height: 8)
                            Text("Paused")
                                .font(.custom("Avenir-Roman", size: 14))
                                .foregroundColor(Color(red: 0.047, green: 0.106, blue: 0.294))
                            Spacer()
                        }
                    }
                }
                .frame(height: 64)
                .frame(maxWidth: .infinity)
                .background(Color.charcoal5)
            }
        }
    }
}

struct AnalyticsDayView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsDayView(logs: [])
            .frame(height: 200)
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
