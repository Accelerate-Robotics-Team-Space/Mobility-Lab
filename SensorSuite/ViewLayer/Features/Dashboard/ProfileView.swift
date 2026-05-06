//
//  ProfileView.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 11/9/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

@MainActor
struct ProfileView: View {
    @EnvironmentObject var driver: ProfileDriver
    @EnvironmentObject var dashboardDriver: DashboardDriver
    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    @EnvironmentObject var patientLandingDriver: PatientLandingDriver
    @State var showEndSession: Bool = false

    @Injected(\.patientManager) private var patientManager

    var body: some View {
        ZStack(alignment: .center) {
            VStack {
                VStack {} // Used for padding
                    .frame(height: 13)
                Image(R.image.atlasLiftEmblem.name)
                    .resizable()
                    .frame(width: 45, height: 45)
                VStack {
                    scrollView
                    hStack
                }
                .padding()
            }
            .presentContent(isPresented: $showEndSession, tag: 21, content: { _ in
                endSessionConfirmation()
            })
            .onChange(of: patientMonitorDriver.syncingState) { _ in
                if driver.endMonitoringState == .endingInitiated
                    && patientMonitorDriver.syncingState == .none {
                    driver.endMonitoringState = .backendEndMonitoring
                }
            }

            if patientMonitorDriver.syncingState == .syncing || !patientMonitorDriver.syncingLogs.isEmpty {
                syncResultPopup()
            } else if driver.endMonitoringState == .error {
                showEndMonitoringError()
            } else if driver.endMonitoringState == .backendEndMonitoring {
                LoadingView(msg: "End Monitoring...")
            }
        }
    }

    @ViewBuilder
    private var scrollView: some View {
        ScrollView {
            PosToAvoidProfileCell(for: patientManager.posToAvoid, modal: $driver.modal)
            PatientLocationProfileCell(for: patientManager.patientLocation, modal: $driver.modal)
                .environmentObject(driver.patientLocationDriver)
            PatientDetailsProfileCell(for: patientManager.currentPatient, modal: $driver.modal)
            PatientDetailsSystemDetailsCell()
        }
    }

    @ViewBuilder
    private var hStack: some View {
        HStack(spacing: 25) {
            Button {
                dashboardDriver.pairWearablesModal = .recalibrate
                dashboardDriver.currentTab = 0
            } label: {
                Text("Recalibrate")
                    .font(.custom("Avenir-Heavy", size: 15))
            }
            .disabled(dashboardDriver.connectedWearables.isEmpty)
            .buttonStyle(!dashboardDriver.connectedWearables.isEmpty ? ALTButtonStyle() : ALTButtonStyle.altBtnIndigoDisabled())
            .frame(width: 116)
            Button {
                Task {
                    await patientMonitorDriver.syncLogs()
                }
            } label: {
                Text("Sync Data")
                    .font(.custom("Avenir-Heavy", size: 15))
            }
            .disabled(
                patientMonitorDriver.syncingState == .syncing
                || !patientMonitorDriver.syncingLogs.isEmpty
                || !driver.endSessionEnabled
            )
            .buttonStyle(ALTButtonStyle())
            Button {
                showEndSession = true
            } label: {
                Text(R.string.localizable.endMonitoring())
                    .font(.custom("Avenir-Heavy", size: 15))
            }
            .disabled(!driver.endSessionEnabled)
            .flatBtnStyle(.clear(subtype: .destructive))
        }
    }
}

extension ProfileView {
    @ViewBuilder
    private func endSessionConfirmation() -> some View {
        DestructiveAlertCard(
            title: R.string.localizable.endMonitoring(),
            msg: R.string.localizable.endSessionConfirmation(),
            primaryString: R.string.localizable.cancel(),
            primaryAction: { showEndSession = false },
            destructiveString: R.string.localizable.end(),
            destructiveAction: {
                showEndSession = false
                DispatchQueue.main.async {
                    self.driver.endMonitoringState = .syncingLogs(attempt: 0)
                }
            },
            textAlignemnt: .center
        )
        .frame(maxWidth: 280)
    }

    @ViewBuilder
    private func showEndMonitoringError() -> some View {
        DestructiveAlertCard(
            title: "Error",
            msg: driver.endMonitoringError ?? "Failed to end monitoring!",
            primaryString: R.string.localizable.cancel(),
            primaryAction: {
                DispatchQueue.main.async {
                    self.driver.endMonitoringState = .none
                }
            },
            destructiveString: R.string.localizable.end(),
            destructiveAction: {
                DispatchQueue.main.async {
                    self.driver.endMonitoringState = .syncingLogs(attempt: 0)
                }
            },
            textAlignemnt: .center
        )
        .frame(maxWidth: 280)
    }

    @ViewBuilder
    private func syncResultPopup() -> some View {
        PopupAlert(
            title: "Sync",
            msg: "Succeded: \(numberSuccess)\nFailed: \(numberFailed)\n",
            image: nil,
            popupBtns: .noCta,
            popupExit: .none
        )
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                DispatchQueue.main.async {
                    patientMonitorDriver.syncingLogs = [:]
                }
            }
        }
    }

    private var numberFailed: Int {
        patientMonitorDriver.syncingLogs.filter({ $0.value == .failed }).count
    }

    private var numberSuccess: Int {
        patientMonitorDriver.syncingLogs.filter({ $0.value == .synced }).count
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject({
                let driver = ProfileDriver(ALTPatient())
                driver.set(patientMonitor: PatientMonitorDriver())
                return driver
            }())
            .environmentObject(DashboardDriver())
    }
}
