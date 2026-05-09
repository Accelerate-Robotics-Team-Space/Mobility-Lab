//
//  DashboardGridView.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/24/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation
import SwiftUI

struct DashboardGridView: View {
    @Binding var currentBMM: BMMViewModel?

    var currentSort: DashboardDriver.SortedBy
    var bmmsToDisplay: [BMMViewModel] = []
    var sortedByUnitDict: [String: [BMMViewModel]]
    var sortedByUnitDictKeys: [String]

    var groupedBMMs: [[BMMViewModel]] {
        return stride(from: 0, to: bmmsToDisplay.count, by: 3).map {
            Array(bmmsToDisplay[$0..<min($0 + 3, bmmsToDisplay.count)])
        }
    }

    private func layout(for width: CGFloat) -> [GridItem] {
        return [
            GridItem(.fixed(width), spacing: 16),
            GridItem(.fixed(width), spacing: 16),
            GridItem(.fixed(width), spacing: 16), 
        ]
    }

    let width: CGFloat

    private func row(group: [BMMViewModel]) -> some View {
        let itemWidth = (width - 46.0) / 3.0
        let itemSize = CGSize(width: itemWidth, height: itemWidth * 1.174)
        return HStack {
            Spacer()
                .frame(width: 4)
            BMMCardView(bmmViewModel: group[0])
                .environmentObject(group[0].turningProtocol)
                .onTapGesture {
                    self.currentBMM = group[0]
                }
                .frame(width: itemSize.width, height: itemSize.height)
            if group.count > 1 {
                Spacer()
                    .frame(width: 16)
                BMMCardView(bmmViewModel: group[1])
                    .environmentObject(group[1].turningProtocol)
                    .onTapGesture {
                        self.currentBMM = group[1]
                    }
                    .frame(width: itemSize.width, height: itemSize.height)
                if group.count > 2 {
                    Spacer()
                        .frame(width: 16)
                    BMMCardView(bmmViewModel: group[2])
                        .environmentObject(group[2].turningProtocol)
                        .onTapGesture {
                            self.currentBMM = group[2]
                        }
                        .frame(width: itemSize.width, height: itemSize.height)
                }
            }
            Spacer()
        }
    }

    var body: some View {
        let itemWidth = (width - 46.0) / 3.0
        let itemSize = CGSize(width: itemWidth, height: itemWidth * 1.174)
        if currentSort != .unit {
            VStack(spacing: 23) {
                ForEach(groupedBMMs, id: \.self) { group in
                    row(group: group)
                }
            }
        } else {
            ForEach(sortedByUnitDictKeys, id: \.self) { key in
                Text(key)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(.charcoal1)
                    .padding(.leading, 16)
                LazyVGrid(columns: layout(for: itemSize.width), spacing: 23) {
                    ForEach(sortedByUnitDict[key] ?? []) { currentBMM in
                        BMMCardView(bmmViewModel: currentBMM)
                            .environmentObject(currentBMM.turningProtocol)
                            .onTapGesture {
                                self.currentBMM = currentBMM
                            }
                            .frame(width: itemSize.width, height: itemSize.height)
                    }
                }
                Spacer()
                    .frame(height: 24)
                if sortedByUnitDictKeys.last != key {
                    Divider()
                }
            }
        }
    }
}

struct DashboardGridView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { _ in
            DashboardGridView(currentBMM: .constant(BMMViewModel()), currentSort: .roomBed,
                              sortedByUnitDict: [:], sortedByUnitDictKeys: [], width: 100)
                .environmentObject(DashboardDriver())
        }
    }
}
