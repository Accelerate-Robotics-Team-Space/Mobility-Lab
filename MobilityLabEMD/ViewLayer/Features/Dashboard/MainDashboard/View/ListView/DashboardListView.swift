//
//  DashboardListView.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 11/8/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DashboardListView: View {
    @EnvironmentObject var dashboardDriver: DashboardDriver

    let aspectRatio: CGFloat

    var body: some View {
        if dashboardDriver.currentSort != .unit {
            VStack {
                HStack {
                    Text("ID")
                        .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                        .frame(width: 71, alignment: .leading)
                    Text("Status")
                        .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                        .frame(width: 143, alignment: .leading)
                    Text("Info")
                        .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                        .frame(width: 100, alignment: .leading)
                    Spacer()
                    HStack(spacing: 0) {
                        Text("Current")
                            .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                            .frame(width: 67)
                            .multilineTextAlignment(.center)
                        Text("Target")
                            .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                            .frame(width: 67)
                            .multilineTextAlignment(.center)
                        Text("Next")
                            .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                            .frame(width: 67)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 201)
                    .offset(x: -6.0)
                    HStack(spacing: 0) {
                        Text("Angle")
                            .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                            .multilineTextAlignment(.center)
                            .frame(width: 46)
                        Spacer()
                            .frame(width: 16)
                        Text("Pitch")
                            .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                            .multilineTextAlignment(.center)
                            .frame(width: 46)
                    }
                    .frame(width: 108)
                    Spacer()
                        .frame(width: 4)
                }
                .padding(.horizontal, 18)
                ScrollView {
                    ForEach(dashboardDriver.bmmsToDisplay, id: \.id) { currentBMM in
                        BMMListView(bmmViewModel: currentBMM)
                            .frame(minHeight: 78)
                            .environmentObject(currentBMM.turningProtocol)
                            .onTapGesture {
                                dashboardDriver.currentBMM = currentBMM
                            }
                            .padding(.horizontal, 2)
                            .padding(.vertical, 2)
                        Spacer()
                            .frame(height: 12)
                    }
                }
            }
        } else if dashboardDriver.currentSort == .unit {
            ScrollView {
                ForEach(dashboardDriver.sortedByUnitDictKeys, id: \.self) { key in
                    Text(key)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.custom("Avenir-Heavy", size: aspectRatio * 20))
                        .foregroundColor(.charcoal1)
                        .padding(.leading, aspectRatio * 16)
                    Spacer()
                        .frame(height: 8)
                    VStack {
                        HStack {
                            Text("ID")
                                .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                                .frame(width: 71, alignment: .leading)
                            Text("Status")
                                .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                                .frame(width: 143, alignment: .leading)
                            Text("Info")
                                .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                                .frame(width: 100, alignment: .leading)
                            Spacer()
                            HStack(spacing: 0) {
                                Text("Current")
                                    .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                                    .frame(width: 67)
                                    .multilineTextAlignment(.center)
                                Text("Target")
                                    .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                                    .frame(width: 67)
                                    .multilineTextAlignment(.center)
                                Text("Next")
                                    .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                                    .frame(width: 67)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 201)
                            .offset(x: -6.0)
                            HStack(spacing: 0) {
                                Text("Angle")
                                    .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                                    .multilineTextAlignment(.center)
                                    .frame(width: 46)
                                Spacer()
                                    .frame(width: 16)
                                Text("Pitch")
                                    .font(.custom("Avenir-Heavy", size: aspectRatio * 12))
                                    .multilineTextAlignment(.center)
                                    .frame(width: 46)
                            }
                            .frame(width: 108)
                            Spacer()
                                .frame(width: 4)
                        }
                        .padding(.horizontal, 18)
                        LazyVStack {
                            ForEach(dashboardDriver.sortedByUnitDict[key] ?? [], id: \.id) { currentBMM in
                                BMMListView(bmmViewModel: currentBMM)
                                    .frame(minHeight: 78)
                                    .environmentObject(currentBMM.turningProtocol)
                                    .onTapGesture {
                                        dashboardDriver.currentBMM = currentBMM
                                    }
                                    .padding(.horizontal, 2)
                                    .padding(.vertical, 2)
                                Spacer()
                                    .frame(height: 12)
                            }
                        }
                    }
                    Spacer()
                        .frame(height: 8)
                    if dashboardDriver.sortedByUnitDictKeys.last != key {
                        Divider()
                    }
                }
            }
        }
    }
}

struct DashboardListView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardListView(aspectRatio: 1.0)
            .environmentObject(DashboardDriver())
    }
}
