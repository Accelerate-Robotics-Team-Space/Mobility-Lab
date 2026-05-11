//
//  DashboardView.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/20/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var patientLandingDriver: PatientLandingDriver
	@StateObject private var profileDriver: ProfileDriver

    @StateObject private var dashboardDriver: DashboardDriver
    @StateObject private var patientMonitor: PatientMonitorWrapper
    @StateObject private var wearablesDriver: WearablesDriver
    @Injected(\.userDefaults) private var userDefaults

    @State private var currentTab: Int = 0

    // MARK: - Init
    init(manager: PatientManagerProtocol? = nil) {
        let manager = manager ?? Container.shared.patientManager.resolve()
        self._dashboardDriver = StateObject(wrappedValue: DashboardDriver(using: manager))
        self._patientMonitor = StateObject(wrappedValue: PatientMonitorWrapper(PatientMonitorDriver(using: manager)))
        self._wearablesDriver = StateObject(wrappedValue: WearablesDriver())
        self._profileDriver = StateObject(wrappedValue: ProfileDriver(manager.currentPatient!))
        UITabBar.appearance().isTranslucent = false
    }

    init(previewWearable: [Wearable]) {
        self._dashboardDriver = StateObject(wrappedValue: DashboardDriver(previewWearable: previewWearable))
        self._patientMonitor = StateObject(wrappedValue: PatientMonitorWrapper(
            PatientMonitorDriver(using: PatientManager.preview),
            isPreview: true
        ))
        self._wearablesDriver = StateObject(wrappedValue: WearablesDriver())
        self._profileDriver = StateObject(wrappedValue: ProfileDriver(ALTPatient()))
        UITabBar.appearance().isTranslucent = false
        self.dashboardDriver.setupFinished = true
    }

    // MARK: - body
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                tabsView
                alertQueue(height: geo.size.height)
                sensorPairing

                if profileDriver.modal == .posToAvoid {
                    dashboardPositionsToAvoidView(geo)
                } else if profileDriver.modal == .location {
                    dashboardPatientLocationView(geo)
                } else if profileDriver.modal == .details {
                    dashboardPatientProfileView(geo)
                } else if wearablesDriver.modal == .popup {
                    wearableInfoView(geo)
                }
                mainStack
                if profileDriver.endMonitoringState == .done {
                    popUpAlert()
                }
            }
            .overlay(overlayView(geo))
            .offset(y: geo.safeAreaInsets.bottom > 0 ? 0 : -10)
            .background(!patientMonitor.alertQueue.isEmpty && dashboardDriver.setupFinished ? .black.opacity(0.4) : .clear)
            .sheet(item: $dashboardDriver.pairWearablesModal) { item in
                if item == .wearablesSetup {
                    pairingStepOne
                }
                if item == .recalibrate {
                    calibrationView
                }
            }
        }
        .onAppear {
            profileDriver.set(patientMonitor: self.patientMonitor.driver)
        }
    }

    @ViewBuilder
    private func alertQueue(height: Double) -> some View {
        if !patientMonitor.alertQueue.isEmpty && dashboardDriver.setupFinished {
            VStack {}
                .frame(height: height * 0.04)
            if !patientMonitor.alertQueue.isEmpty && dashboardDriver.setupFinished {
                PatientMonitorAlertQueue()
                    .environmentObject(patientMonitor.driver)
                    .environmentObject(AudioAlertPlayer())
                    .padding(.horizontal, 16)
                    .zIndex(2)
            } else {
                VStack {}
                    .frame(height: height * 0.11)
            }
        }
    }

    @ViewBuilder
    private var sensorPairing: some View {
        if dashboardDriver.sensorAttempingToPair {
            ZStack {}
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.4))
                .overlay {
                    pairingInProcessOverlay
                }
        }
    }

    @ViewBuilder
    private var mainStack: some View {
        VStack {
            HStack {
                Spacer()
                    .frame(width: 16)
                circleMqttConnectionView
                mqttConnectionView
                if !dashboardDriver.isConnected {
                    Spacer()
                    noInternetView
                }
                Spacer()
                    .frame(width: 16)
            }
            .background(dashboardDriver.isConnected ? .clear : .vermillion)
            .padding(.top, 16)
            Spacer()
        }
    }

    @ViewBuilder
    private var tabsView: some View {
        TabView(selection: $currentTab) {
            patientMonitorTabView
            wearablesTabView
            analyticsTabView
            profileTabView
        }
        .disabled(!patientMonitor.alertQueue.isEmpty && dashboardDriver.setupFinished ? true : false)
    }

    @ViewBuilder
    private var patientMonitorTabView: some View {
        VStack {
            if !dashboardDriver.setupFinished {
                patientMonitorSetupView
            } else if dashboardDriver.setupFinished {
                patientMonitorView
            }
        }
        .tabItem {
            Image(R.image.dashboard.name)
                .renderingMode(.template)
                .foregroundColor(.charcoal3)
            Text(R.string.localizable.monitor())
        }
        .tag(0)
    }

    @ViewBuilder
    private var patientMonitorSetupView: some View {
        PatientMonitorSetupView()
            .environmentObject(dashboardDriver)
    }

    @ViewBuilder
    private var patientMonitorView: some View {
        PatientMonitorView()
            .environmentObject(dashboardDriver)
            .environmentObject(patientMonitor.driver)
            .environmentObject(patientLandingDriver)
            .environmentObject(AudioAlertPlayer())
    }

    @ViewBuilder
    private var wearablesTabView: some View {
        WearablesView(listOfWearables: $dashboardDriver.connectedWearables)
            .environmentObject(patientMonitor.driver)
            .environmentObject(wearablesDriver)
            .tabItem {
                Image(R.image.wearables.name)
                    .renderingMode(.template)
                    .foregroundColor(.charcoal3)
                Text(R.string.localizable.wearables())
            }
            .tag(1)
    }

    @ViewBuilder
    private var analyticsTabView: some View {
        AnalyticsView()
            .tabItem {
                Image(R.image.analytics.name)
                    .renderingMode(.template)
                    .foregroundColor(.charcoal3)
                Text(R.string.localizable.analytics())
            }
            .tag(2)
    }

    @ViewBuilder
    private var profileTabView: some View {
        ProfileView()
            .environmentObject(profileDriver)
            .environmentObject(dashboardDriver)
            .environmentObject(patientMonitor.driver)
            .environmentObject(patientLandingDriver)
            .tabItem {
                Image(R.image.profile.name)
                    .renderingMode(.template)
                    .foregroundColor(.charcoal3)
                Text(R.string.localizable.profile())
            }
            .tag(3)
    }

    @ViewBuilder
    private var pairingInProcessOverlay: some View {
        VStack {
            Spacer()
            Text("Pairing in process...\nPlease wait...")
                .font(.custom("Avenir-Heavy", size: 24))
                .foregroundColor(.white)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func dashboardPositionsToAvoidView(_ geo: GeometryProxy) -> some View {
        FlexibleSheet(height: geo.size.height * 0.59) {
            DashboardSettingPositionsToAvoidView(flow: $profileDriver.modal, isMonitoring: patientMonitor.isMonitoring)
                .background(Color.black.opacity(0.1))
        }
        .transition(.opacity)
        .zIndex(1)
    }

    @ViewBuilder
    private func dashboardPatientLocationView(_ geo: GeometryProxy) -> some View {
        FlexibleSheet(height: geo.size.height * 0.61) {
            DashboardSettingPatientLocationView(flow: $profileDriver.modal, patientLocationDriver: profileDriver.patientLocationDriver)
                .background(Color.black.opacity(0.1))
        }
        .transition(.opacity)
        .zIndex(1)
    }

    @ViewBuilder
    private func dashboardPatientProfileView(_ geo: GeometryProxy) -> some View {
        FlexibleSheet(height: geo.size.height * 0.60) {
            DashboardSettingPatientProfileView(flow: $profileDriver.modal)
                .background(Color.black.opacity(0.1))
        }
        .transition(.opacity)
        .zIndex(1)
    }

    @ViewBuilder
    private func wearableInfoView(_ geo: GeometryProxy) -> some View {
        FlexibleSheet(height: geo.size.height * 0.95) {
            VStack {
                WearableInfoView(
                    patientMonitorDriver: patientMonitor.driver,
                    wearable: $wearablesDriver.wearable,
                    isTrackingStr: $patientMonitor.isTrackingStr,
                    modal: $wearablesDriver.modal
                )
                .frame(height: geo.size.height * 0.95)
            }
        }
        .transition(.opacity)
        .zIndex(1)
    }

    @ViewBuilder
    private var circleMqttConnectionView: some View {
        Circle()
            .strokeBorder(Color.blue, lineWidth: 0.2)
            .background(Circle().foregroundColor(dashboardDriver.isConnected ? dashboardDriver.mqttConStateColor : .red1))
            .frame(width: 10, height: 10)
    }

    @ViewBuilder
    private var mqttConnectionView: some View {
        Text(dashboardDriver.mqttConText)
            .font(.custom("Avenir-Heavy", size: 12))
            .foregroundColor(dashboardDriver.isConnected ? .black : .white)
    }

    @ViewBuilder
    private var noInternetView: some View {
        Text("No Internet Connection")
            .font(.custom("Avenir-Heavy", size: 12))
            .foregroundColor(.white)
    }

    @ViewBuilder
    private func overlayView(_ geo: GeometryProxy) -> some View {
        Rectangle()
            .stroke(Color.red1, lineWidth: 5)
            .frame(width: geo.size.width * 0.995, height: geo.size.height * 1.0247)
            .opacity(!patientMonitor.alertQueue.isEmpty && dashboardDriver.setupFinished ? 1 : 0)
    }

    @ViewBuilder
    private var pairingStepOne: some View {
        if #available(iOS 17.0, *) {
            ZStack(alignment: .bottom) {
                NavigationStack {
                    PairingWearableStepOne(
                        pairWearablesFlow: $dashboardDriver.pairWearablesModal,
                        request: dashboardDriver.feedRequest ?? DataFeedRequest.previewRequest
                    )
                    .environmentObject(dashboardDriver)
                    .environmentObject(patientMonitor.driver)
                }
            }
        } else {
            ZStack(alignment: .bottom) {
                NavigationView {
                    PairingWearableStepOne(
                        pairWearablesFlow: $dashboardDriver.pairWearablesModal,
                        request: dashboardDriver.feedRequest ?? DataFeedRequest.previewRequest
                    )
                    .environmentObject(dashboardDriver)
                    .environmentObject(patientMonitor.driver)
                }
            }
        }
    }

    @ViewBuilder
    private var calibrationView: some View {
        if #available(iOS 17.0, *) {
            NavigationStack {
                if !dashboardDriver.connectedWearables.isEmpty {
                    let wearable = dashboardDriver.connectedWearables[0]
                    CalibrateInstructions(
                        pairWearablesFlow: $dashboardDriver.pairWearablesModal,
                        wearableId: wearable.id.formattedId()
                    )
                    .environmentObject(dashboardDriver)
                }
            }
        } else {
            NavigationView {
                if !dashboardDriver.connectedWearables.isEmpty {
                    let wearable = dashboardDriver.connectedWearables[0]
                    CalibrateInstructions(
                        pairWearablesFlow: $dashboardDriver.pairWearablesModal,
                        wearableId: wearable.id.formattedId()
                    )
                    .environmentObject(dashboardDriver)
                }
            }
        }
    }

    @ViewBuilder
    private func popUpAlert() -> some View {
        ZStack(alignment: .center) {
            PopupAlert(title: "Reminder",
                       msg: "Make sure to put the Sensor back to BMM dock",
                       image: R.image.getWearable.name,
                       popupBtns: .noCta,
                       popupExit: .none)
            .onAppear {
                dashboardDriver.setupFinished = false
                Timer.scheduledTimer(withTimeInterval: 7, repeats: false) { _ in
                    DispatchQueue.main.async {
                        patientLandingDriver.currentScreen = .landing
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4))
        .allowsHitTesting(true)
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(previewWearable: Wearable.previewWearables)
            .environmentObject(PatientLandingDriver())
//            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
