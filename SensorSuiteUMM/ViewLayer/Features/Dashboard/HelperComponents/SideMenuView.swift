//
//  SideMenuView.swift
//  SensorSuite BMM
//
//  Created by Vadym Riznychok on 11/3/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct SideMenuView: View {
    @StateObject var dashboardDriver: DashboardDriver

    @State private var showFilterUnitOptions = false
    @State private var showBMMs = false

    @Binding var resetRegistration: Bool

    private var bmmsList: [BMMViewModel] {
        return dashboardDriver.registeredBMMs.sorted { left, right in
            if left.cardData.isAlive && !right.cardData.isAlive {
                return true
            } else if !left.cardData.isAlive && right.cardData.isAlive {
                return false
            } else {
                return left.cardData.lastSeen?.daysLastSeen ?? 31 < right.cardData.lastSeen?.daysLastSeen ?? 31
            }
        }
    }

    var body: some View {
        ZStack {
            HStack {
                Divider()
                VStack(alignment: .leading, content: {
                    Button {
                        showFilterUnitOptions.toggle()
                    } label: {
                        Text("Filter")
                            .font(.custom("Avenir-Heavy", size: 20))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 8)
                    if showFilterUnitOptions {
                        List(dashboardDriver.units) { unit in
                            Button {
                                if dashboardDriver.selectedUnitName == unit.name {
                                    dashboardDriver.selectedUnitName = ""
                                } else {
                                    dashboardDriver.selectedUnitName = unit.name ?? ""
                                }
                            } label: {
                                HStack {
                                    Text(unit.name ?? "Unknown")
                                        .font(.custom("Avenir-Roman", size: 20))
                                        .foregroundColor(dashboardDriver.selectedUnitName == unit.name ? .yellow1 : .black)
                                    Spacer()
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                    }
                    Button { } label: {
                        Text("Reports")
                            .font(.custom("Avenir-Heavy", size: 20))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 8)
                    Button {
                        showBMMs.toggle()
                    } label: {
                        Text("BMM List")
                            .font(.custom("Avenir-Heavy", size: 20))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 8)
                    if showBMMs {
                        List {
                            ForEach(bmmsList, id: \.self) { bmm in
                                VStack {
                                    SideMenuBMMView(deviceId: bmm.deviceId,
                                                    roomBed: bmm.roomBed,
                                                    sensorId: bmm.currentWearable?.wearableSerialNum,
                                                    isAlive: bmm.cardData.isAlive,
                                                    daysLastSeen: bmm.cardData.lastSeen?.daysLastSeen ?? 31)
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(.init())
                            }
                        }
                        .padding(.trailing, 8)
                        .scrollContentBackground(.hidden)
                        .listStyle(PlainListStyle())
                    }
                    Divider()
                    Button {
                        resetRegistration = true
                    } label: {
                        Text("Reset registration")
                            .font(.custom("Avenir-Heavy", size: 20))
                            .foregroundColor(.red)
                    }
                    .padding(.top, 8)
                    Spacer()
                    Spacer()
                        .frame(height: 60)
                })
                .padding(.top, 24)
                .padding(.leading, 16)
                Spacer()
            }
        }
        .background(Color.aqua5)
    }
}

struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuView(dashboardDriver: DashboardDriver(), resetRegistration: .constant(false))
    }
}
