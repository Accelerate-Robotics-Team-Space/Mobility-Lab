//
//  DashboardView.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/21/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var deviceRegistrationLandingDriver: DeviceRegistrationLandingDriver
    @StateObject var dashboardDriver = DashboardDriver()
    @Injected(\.securityService) 
    private var securityService

    @State var resetRegistration = false
    @State var showSideView = false
    @State var selectedBMM: BMMViewModel?

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                DashboardScrollContainerView()
                    .environmentObject(dashboardDriver)
                    .padding(.top, 80)
                DashboardNavigationView(showSideView: $dashboardDriver.showSideMenu,
                                        displayList: $dashboardDriver.displayList,
                                        currentSort: $dashboardDriver.currentSort,
                                        expandSorting: $dashboardDriver.expandSorting)
                    .padding(.top, 25)
                    .padding(.bottom, 6)
                    .frame(height: 70)
                VStack {
                    HStack {
                        Spacer()
                            .frame(width: 16)
                        Circle()
                            .strokeBorder(Color.blue, lineWidth: 0.2)
                            .background(Circle().foregroundColor(dashboardDriver.isConnected ? dashboardDriver.mqttConStateColor : .red1))
                            .frame(width: 10, height: 10)
                        Text(dashboardDriver.mqttConText)
                            .font(.custom("Avenir-Heavy", size: 12))
                            .foregroundColor(dashboardDriver.isConnected ? .black : .white)
                        if !dashboardDriver.isConnected {
                            Spacer()
                            Text("No Internet Connection")
                                .font(.custom("Avenir-Heavy", size: 12))
                                .foregroundColor(.white)
                        }
                        Spacer()
                            .frame(width: 16)
                    }
                    .background(dashboardDriver.isConnected ? .clear : .vermillion)
                }
                if dashboardDriver.showSideMenu == true {
                    HStack {
                        Spacer()
                        VStack {
                            SideMenuView(dashboardDriver: dashboardDriver, resetRegistration: $resetRegistration)
                        }
                        .frame(width: 300)
                    }
                    .padding(.top, 78)
                }
            }
            .onChange(of: $dashboardDriver.currentBMM.wrappedValue, perform: { bmm in
                selectedBMM = bmm
                bmm?.loadAnalyticsData()
            })
            .fullScreenCover(item: $selectedBMM) { bmm in
                BMMInfoView(bmmViewModel: bmm)
                    .environmentObject(dashboardDriver)
                    .background(Color.black.opacity(0.4))
            }
            .alert(isPresented: $resetRegistration) {
                registrationAgainConfirmation
            }
        }
    }
}

extension DashboardView {
    private var registrationAgainConfirmation: Alert {
        return Alert(title: Text("Reset Registration"),
                     message: Text("Do you want to reset registration to re-register this device to another facility?"),
                     primaryButton: .default(R.string.localizable.cancel.text,
                                             action: { resetRegistration = false }),
                     secondaryButton: .destructive(Text("Reset"),
                                                   action: {
            securityService.resetAll()
            dashboardDriver.resetRegistration()
            deviceRegistrationLandingDriver.currentScreen = .landing
        }))
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(DeviceRegistrationLandingDriver())
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPadAirUMM()))
    }
}
