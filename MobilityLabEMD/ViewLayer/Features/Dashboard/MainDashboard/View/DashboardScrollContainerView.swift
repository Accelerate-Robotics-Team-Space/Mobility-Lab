//
//  DashboardScrollContainerView.swift
//  MobilityLabEMD
//
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DashboardScrollContainerView: View {
    @EnvironmentObject var dashboardDriver: DashboardDriver

    var body: some View {
        GeometryReader { geo in
                TabView {
                    if !dashboardDriver.displayList {
                        ScrollView {
                            DashboardGridView(currentBMM: $dashboardDriver.currentBMM,
                                              currentSort: dashboardDriver.currentSort,
                                              bmmsToDisplay: dashboardDriver.bmmsToDisplay,
                                              sortedByUnitDict: dashboardDriver.sortedByUnitDict,
                                              sortedByUnitDictKeys: dashboardDriver.sortedByUnitDictKeys,
                                              width: geo.size.width)
                            .padding([.top, .bottom])
                            .padding([.leading, .trailing], 3)
                        }
                        .animation(.easeInOut, value: dashboardDriver.displayList)
                    } else {
                        ScrollView {
                            DashboardListView(aspectRatio: geo.size.width / 820.0)
                                .frame(maxHeight: .infinity, alignment: .top)
                                .padding(.vertical)
                                .padding(.horizontal, 16)
                                .environmentObject(dashboardDriver)
                        }
                        .animation(.easeInOut, value: dashboardDriver.displayList)
                    }
                }
                .background(Color.charcoal5)
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        }
        .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height

                if abs(horizontalAmount) > abs(verticalAmount) && horizontalAmount < 0 {
                    withAnimation {
                        dashboardDriver.displayList = true
                        dashboardDriver.expandSorting = false
                    }
                } else if abs(horizontalAmount) > abs(verticalAmount) && horizontalAmount >= 0 {
                    withAnimation {
                        dashboardDriver.displayList = false
                        dashboardDriver.expandSorting = false
                    }
                }
            })
    }
}

struct DashboardScrollContainerView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardScrollContainerView()
            .environmentObject(DashboardDriver())
    }
}
