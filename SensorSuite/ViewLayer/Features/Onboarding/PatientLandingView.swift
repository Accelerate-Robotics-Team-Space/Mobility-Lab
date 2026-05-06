//
//  PatientLandingView.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/13/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct PatientLandingView: View {
    @StateObject var patientLandingDriver = PatientLandingDriver()
    @Injected(\.userDefaults) private var userDefaults
    @State private var copiedAlertIsShown = false
    @State private var infoTapCount: Int = 0

    private let manager: PatientManagerProtocol

    // MARK: - Computed Variables
    private var alert: Alert {
        Alert(
            title: Text(patientLandingDriver.alertTitle),
            message: Text(patientLandingDriver.alertBody),
            dismissButton: .default(R.string.localizable.ok.text)
        )
    }
    
    private var actionSheet: ActionSheet {
        var btns = patientLandingDriver.actionSheetBtns.map {
            ActionSheet.Button.default(Text($0.key), action: $0.value)
        }
        
        btns.append(.cancel(R.string.localizable.cancel.text))
        return ActionSheet(
            title: Text(R.string.localizable.adminPanel(userDefaults.facilityName ?? "Unknown")),
            message: nil,
            buttons: btns
        )
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                mainView
                deviceInfoView(geo)
            }
        }
        .actionSheet(isPresented: $patientLandingDriver.showAdminPanel, content: { actionSheet })
        .alert(isPresented: $patientLandingDriver.showAlert, content: { alert })
        .fullScreenCover(
            item: $patientLandingDriver.modal,
            onDismiss: {
                patientLandingDriver.updateRegistrationState()
            },
            content: { item in
                if item == .newPatient {
                    if #available(iOS 17.0, *) {
                        NavigationStack {
                            newPatientView
                        }
                    } else {
                        NavigationView {
                            newPatientView
                        }
                    }
                } else if item == .devMenu {
                    DevMenuView($patientLandingDriver.modal, manager: manager)
                } else if item == .registerDevice {
                    registerView
                }
            }
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    private var mainView: some View {
        VStack {
            if patientLandingDriver.currentScreen == .landing {
                PatientHomeView(driver: patientLandingDriver, audioAlertPlayer: AudioAlertPlayer())
            } else if patientLandingDriver.currentScreen == .greet {
                PatientGreetView(driver: patientLandingDriver)
            } else if patientLandingDriver.currentScreen == .dashboard {
                DashboardView(manager: manager)
                    .environmentObject(patientLandingDriver)
            } else if patientLandingDriver.currentScreen == .demoDashboard {
                DashboardView(previewWearable: Wearable.previewWearables)
                    .environmentObject(patientLandingDriver)
            }
        }
    }

    @ViewBuilder
    private func deviceInfoView(_ geo: GeometryProxy) -> some View {
        VStack {
            Text(DeviceConstants.getBuildInfoStr(facilityName: userDefaults.facilityName))
                .textStyle(.overline, color: .silver)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, hasANotch ? -15 : 0)
        .frame(width: geo.size.width)
        .background(patientLandingDriver.currentScreen.backgroundColor)
    }

    @ViewBuilder
    private var newPatientView: some View {
        ZStack(alignment: .bottom) {
            PatientLocationView(patientLandingDriver: patientLandingDriver, patientFlow: $patientLandingDriver.modal)
            Text(DeviceConstants.getBuildInfoStr(facilityName: userDefaults.facilityName))
                .textStyle(.overline, color: .silver)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var registerView: some View {
        ZStack(alignment: .bottom) {
            EnrollmentView($patientLandingDriver.modal)
                .environmentObject(patientLandingDriver)
            #if DEV || QA
            Button {
                let info = """
                Device:\t\t\(UIDevice.current.name)
                OS:\t\t\t\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
                Build:\t\t\(DeviceConstants.versionNumStr) (\(DeviceConstants.buildNumStr))
                Device ID:\t\(patientLandingDriver.deviceID)
                """
                UIPasteboard.general.string = info
                copiedAlertIsShown = true
                infoTapCount += 1
            } label: {
                VStack(spacing: 3) {
                    Text(patientLandingDriver.buildInfo)
                        .textStyle(.overline, color: .silver)
                        .multilineTextAlignment(.center)
                    Text( "Device ID: " + patientLandingDriver.deviceID)
                        .textStyle(.overline, color: .silver)
                }
            }
            .disabled(infoTapCount > 0)
            .padding(.bottom, -16)
            #else
            Text(patientLandingDriver.buildInfo)
                .textStyle(.overline, color: .silver)
                .multilineTextAlignment(.center)
            #endif
        }
        .alert(Text("Details Copied to Clipboard"), isPresented: $copiedAlertIsShown, presenting: nil, actions: {})
    }

    // MARK: - Init
    init(_ manager: PatientManagerProtocol? = nil) {
        self.manager = manager ?? Container.shared.patientManager.resolve()
    }
}

// MARK: - Preview
struct PatientLandingView_Previews: PreviewProvider {
    static var previews: some View {
        PatientLandingView(PatientManager.preview)
            .previewDevice((PreviewDevice(rawValue: R.string.localizable.iPhone8Plus())))
    }
}
