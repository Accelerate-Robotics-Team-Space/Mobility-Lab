//
//  AnalyticsCumulativeCellView.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 1/25/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct AnalyticsCumulativeCellView: View {
    let dict: [PositionalFlagCategory: Int64]
    let pausedDuration: Int64
    let wrongDuration: Int64

    private let keys: [PositionalFlagCategory] = [.left, .supine, .right]

    var body: some View {
        ScrollView {
            Spacer()
                .frame(height: 16)

            positionsListView

            if pausedDuration > 0 {
                pausedDurationView
            }
            if wrongDuration > 0 {
                wrongDurationView
            }
        }
    }

    @ViewBuilder
    private var positionsListView: some View {
        ForEach(keys, id: \.abbreviation) { key in
            let value = dict[key, default: 0]
            let partial = key == .left ? dict[.partialLeft, default: 0] : (key == .right ? dict[.partialRight, default: 0] : 0)
            if value != 0 || partial != 0 {
                maxDurationView(value, partial: partial, key: key)
            }
        }
    }

    @ViewBuilder
        private func maxDurationView(_ value: Int64, partial: Int64, key: PositionalFlagCategory) -> some View {
            VStack {
                AnalyticsCumulativeDisplay(
                    title: key.description,
                    totalTime: value,
                    maxTime: maxDuration,
                    partialTime: partial,
                    color: key.analyticsColor
                )
                .id("CumulativeCell" + key.description)
                .padding(.horizontal)
                Divider()
            }
            .frame(height: 54)
    }

    @ViewBuilder
    private var pausedDurationView: some View {
        AnalyticsCumulativeDisplay(
            title: "Paused",
            totalTime: pausedDuration,
            maxTime: maxDuration,
            partialTime: 0,
            color: .charcoal3
        )
        .frame(height: 54)
        .padding(.horizontal)
        .id("CumulativeCellPaused")
    }

    @ViewBuilder
    private var wrongDurationView: some View {
        AnalyticsCumulativeDisplay(
            title: "Non-Target/Deficient",
            totalTime: wrongDuration,
            maxTime: maxDuration,
            partialTime: 0,
            color: .red3
        )
        .frame(height: 54)
        .padding(.horizontal)
        .id("CumulativeCellWrong")
    }

    private var maxDuration: Int64 {
        max(
            dict[.other, default: 0],
            dict[.left, default: 0] + dict[.partialLeft, default: 0],
            dict[.right, default: 0] + dict[.partialRight, default: 0],
            dict[.supine, default: 0],
            pausedDuration,
            wrongDuration
        )
    }
}

struct AnalyticsCumulativeCellView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsCumulativeCellView(
            dict: [
                PositionalFlagCategory.left: 86340000, // 23h 59m
                PositionalFlagCategory.right: 28800000, // 8h 00m
                PositionalFlagCategory.supine: 18180000, // 5h 3m
                PositionalFlagCategory.other: 3000000, // 50m
            ],
            pausedDuration: 18180000,
            wrongDuration: 300000  // 5h 3m
        )
    }
}
