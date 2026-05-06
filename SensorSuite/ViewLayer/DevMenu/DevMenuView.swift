//
//  DevMenuView.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/10/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct DevMenuView: View {
    @Binding var devMenu: PatientLandingDriver.ActiveModal?
    @State private var showDashboard = false
    @State private var isLoading = false
    @State private var showResetAlert = false
    @State private var showResetDatabaseAlert = false
    @State private var showResetAll = false
    
    let manager: PatientManagerProtocol

    @Injected(\.securityService) private var securityService
    @Injected(\.patientManager) private var patientManager
    @Injected(\.userDefaults) private var userDefaults

    // MARK: - Computed Variables
    var resetAlert: Alert {
        let resetAction = {
            securityService.resetDeviceRegistered()
            devMenu = nil
        }
        
        return Alert(title: Text("Reset Registration"),
                     message: Text("Are you sure you want to reset your device registration?"),
                     primaryButton: .default(Text("YES!"),
                                             action: resetAction),
                     secondaryButton: .cancel(Text("Cancel")))
    }
    
    var resetDatabaseAlert: Alert {
        let resetAction = {
            securityService.resetTable()
            devMenu = nil
        }
        
        return Alert(title: Text("Truncate Database"),
                     message: Text("Are you sure you want to reset your local database?"),
                     primaryButton: .default(Text("YES!"),
                                             action: resetAction),
                     secondaryButton: .cancel(Text("Cancel")))
    }
    
    var resetAllAlert: Alert {
        let resetAction = {
            securityService.resetAll()
            devMenu = nil
        }
        
        return Alert(title: Text("Factory Reset"),
                     message: Text("Are you sure you want to do factory reset?"),
                     primaryButton: .default(Text("YES!"),
                                             action: resetAction),
                     secondaryButton: .cancel(Text("Cancel")))
    }
    
    var actionSheet: ActionSheet {
        ActionSheet(title: Text("Admin Panel"),
                    message: Text("In Dev"),
                    buttons: [.default(Text("OK"))])
    }
    
    var navBarBtn: some View {
        Button(action: {
            devMenu = nil
        }, label: {
            Image(systemName: "xmark.square.fill")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.aqua)
                .frame(width: 44, height: 44)
        })
    }
    
    // MARK: - Body
    var body: some View {
        if #available(iOS 17.0, *) {
            NavigationStack {
                bodyContents
            }
            .accentColor(.aqua)
        } else {
            NavigationView {
                bodyContents
            }
            .accentColor(.aqua)
        }
    }
    
    // MARK: - Init
    init(_ flow: Binding<PatientLandingDriver.ActiveModal?>, manager: PatientManagerProtocol) {
        self._devMenu = flow
        self.manager = manager
    }

    var bodyContents: some View {
        ZStack {
            // NavigationLink(
            //     destination: DashboardView(manager: manager)
            //         .environmentObject(PatientLandingDriver()),
            //     isActive: $showDashboard,
            //     label: { EmptyView() })

            Form {
                NavigationLink("Design Lib",
                               destination: DesignLibView())
                .menuCellStyle()

                Button(action: {
                    isLoading = true
                    Task {
                        await patientManager.startDevSession()
                    }
                    showDashboard.toggle()
                }, label: {
                    Text("Dashboard")
                })
                .menuCellStyle()

                // NavigationLink(
                //     "Position Circle",
                //     destination: TurnTrackerPositionView(diameter: 150,
                //                                          currentPosition: .constant(.back),
                //                                          allPositions: [])
                //         .frame(width: 500, height: 500)
                //         .background(Color.charcoal)
                // )
                // .menuCellStyle()

                Button(action: {
                    showResetAlert.toggle()
                }, label: {
                    Text("Reset Registration")
                        .frame(maxWidth: .infinity)
                })
                .flatBtnStyle()

                Button(action: {
                    showResetDatabaseAlert.toggle()
                }, label: {
                    Text("Truncate Local Database")
                        .frame(maxWidth: .infinity)
                })
                .flatBtnStyle(.primary(subtype: .destructive))
                .alert(isPresented: $showResetDatabaseAlert, content: { resetDatabaseAlert })

                Button(action: {
                    showResetAll.toggle()
                }, label: {
                    Text("Factory Reset")
                        .frame(maxWidth: .infinity)
                })
                .flatBtnStyle(.primary(subtype: .destructive))
                .alert(isPresented: $showResetAll, content: { resetAllAlert })

                Button(action: {
                    testerBtnPress()
                }, label: {
                    Text("Tester Button")
                })
                .flatBtnStyle()
            }

            if isLoading {
                ProgressView()
            }
        }
        .navigationBarTitle("Dev Menu")
        .navigationBarItems(trailing: navBarBtn)
        .alert(isPresented: $showResetAlert, content: { resetAlert })
    }

    fileprivate init() {
        self._devMenu = .constant(nil)
        self.manager = PatientManager.preview
    }
}

// MARK: - Private
private extension DevMenuView {
    static let router = MqttRouter(for: DataFeedTopics.self)
    
    func testerBtnPress() {
        Self.router.publish(.appVersion(ver: "1.1.1"), to: .appVersion(facilityID: userDefaults.facilityId, baseStationGuid: userDefaults.baseStationGuid))
    }
}

// MARK: - Preview
@available(iOS 15.0, *)
struct DevMenuView_Previews: PreviewProvider {
    static var previews: some View {
        DevMenuView()
    }
}
