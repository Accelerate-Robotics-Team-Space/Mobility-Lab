//
//  BMMDetailsAnalyticsView.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 11/29/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BMMDetailsAnalyticsView: View {
    @ObservedObject var bmmViewModel: BMMViewModel

    var body: some View {
        VStack(spacing: 0) {
            AnalyticsDayView(logs: bmmViewModel.analyticsData.logs, timestamps: bmmViewModel.analyticsData.timestamps)
            Spacer()
                .frame(height: 24)
            HStack(alignment: .top) {
                AnalyticsCumulativeCellView(dict: bmmViewModel.analyticsData.positionDurations,
                                            pausedDuration: bmmViewModel.analyticsData.pausedDuration,
                                            wrongDuration: bmmViewModel.analyticsData.wrongDuration)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 1)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                VStack(spacing: 0) {
                    WearableInfoView(wearableViewModel: bmmViewModel.currentWearable ?? WearableViewModel(id: ""),
                                     bmmViewModel: bmmViewModel)
                    Divider()
                    PatientDetailsView(bmmViewModel: bmmViewModel)
                    Divider()
                    SystemInfoCell(bmmViewModel: bmmViewModel)
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 1)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
//            .padding(.top, 24)
        }
    }
}

struct BMMDetailsAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        BMMDetailsAnalyticsView(bmmViewModel: BMMViewModel())
    }
}
