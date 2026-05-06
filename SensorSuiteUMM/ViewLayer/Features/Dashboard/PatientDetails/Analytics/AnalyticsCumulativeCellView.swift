//
//  AnalyticsCumulativeCellView.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 11/1/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct AnalyticsCumulativeCellView: View {
    let dict: [PositionalFlagCategory: Int]
    let pausedDuration: Int
    let wrongDuration: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(R.image.analyticsIcon.name)
                VStack {
                    Text("Summary")
                        .font(.custom("Avenir-Heavy", size: 20.34))
                        .foregroundColor(.charcoal1)
                    Text("Last 24 hours")
                        .font(.custom("Avenir-Roman", size: 14.24))
                        .foregroundColor(.charcoal1)
                }
                Spacer()
            }
            let keys: [PositionalFlagCategory] = [.left, .supine, .right]
            let maxDuration = max(
                dict[.other, default: 0],
                dict[.left, default: 0] + dict[.partialLeft, default: 0],
                dict[.right, default: 0] + dict[.partialRight, default: 0], 
                dict[.supine, default: 0],
                pausedDuration,
                wrongDuration
            )
            ForEach(keys, id: \.self) { key in
                let value = dict[key, default: 0]
                let partial = key == .left ? dict[.partialLeft, default: 0] : (key == .right ? dict[.partialRight, default: 0] : 0)
                if value != 0 || partial != 0 {
                    VStack {
                        AnalyticsCumulativeDisplay(title: key.description,
                                                   totalTime: value,
                                                   maxTime: maxDuration,
                                                   partialTime: partial,
                                                   color: key == .other ? .gray : .green3)
                        .id("CumulativeCell" + key.description)
                        .padding(.horizontal)
                        Divider()
                    }
                    .frame(height: 54)
                }
            }
            if pausedDuration > 0 {
                AnalyticsCumulativeDisplay(title: "Paused",
                                           totalTime: pausedDuration,
                                           maxTime: maxDuration,
                                           partialTime: 0,
                                           color: .charcoal3)
                .frame(height: 54)
                .padding(.horizontal)
                .id("CumulativeCellPaused")
            }
            if wrongDuration > 0 {
                AnalyticsCumulativeDisplay(title: "Non-Target/Deficient",
                                           totalTime: wrongDuration,
                                           maxTime: maxDuration,
                                           partialTime: 0,
                                           color: .red3)
                .frame(height: 54)
                .padding(.horizontal)
                .id("CumulativeCellPaused")
            }
        }
    }
}

struct AnalyticsCumulativeCellView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsCumulativeCellView(
            dict: [
                PositionalFlagCategory.left: 86340000, // 23h 59m
                PositionalFlagCategory.right: 28800000, // 8h 00m
                PositionalFlagCategory.supine: 18180000, // 50m
            ],
            pausedDuration: 18180000,
            wrongDuration: 8634000 // 5h 3m
        )
    }
}
