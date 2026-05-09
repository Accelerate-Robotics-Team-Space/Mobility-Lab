//
//  PatientMonitorView.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 11/8/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import AVFoundation
import SwiftUI

struct PatientMonitorView: View {
    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    @EnvironmentObject var patientLandingDriver: PatientLandingDriver
    @EnvironmentObject var dashboardDriver: DashboardDriver
    @EnvironmentObject var audioAlertPlayer: AudioAlertPlayer

    @State private var rollDegree: Double = 0.0
    @State private var pitchDegree: Double = 0.0
    @State private var wrongPositionSoundTimer: Timer?
    @State private var turnPatientSoundTimer: Timer?
    @State private var lowBatterySoundTimer: Timer?
    @State private var compliancePercentage: Int = 1
    @State private var complianceBarColor: Color = .green1
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                if !patientMonitorDriver.alertQueue.isEmpty {
                   backgroundView
                }
                MonitorRayOverlay()
                    .environmentObject(patientMonitorDriver)
                VStack(spacing: 16) {
                    headerView(geo)
                    mainStack(geo)
                }
                if patientLandingDriver.isDevMode || patientLandingDriver.isTestMode {
                    settingsView
                }
                if let number = dashboardDriver.roomBedNum {
                    roomNumberView(number)
                }
            }
            .sheet(isPresented: $patientMonitorDriver.showConfig) {
                configTimerView
            }
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        VStack {}
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity
            )
            .zIndex(1)
            .background(Color.black.opacity(0.4))
    }

    @ViewBuilder
    private func headerView(_ geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            AtlasLogoPadder()
                .padding(.top, 12)
            VStack {}
                .frame(height: geo.size.height * 0.08)
            Image(patientMonitorDriver.desiredPosition.imageStr)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .conditionalModifier(patientMonitorDriver.currentState == .onPause || !patientMonitorDriver.isWearableConnected) {
                    $0.grayscale(0.9995)
                }
                .frame(width: geo.size.width * 0.8)
            Text(R.string.localizable.patientMonitorTargetPosition(patientMonitorDriver.desiredPosition.description))
                .font(.custom("Avenir-Heavy", size: 16))
                .padding(.top, 4)
        }

    }

    @ViewBuilder
    private func mainStack(_ geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
            RollPitchVisualizations()
                .environmentObject(patientMonitorDriver)
                .opacity(patientMonitorDriver.currentState == .onPause || !patientMonitorDriver.isWearableConnected ? 0 : 1)
            Spacer()
                .frame(height: geo.size.height > 700 ? 20 : 1)
            MonitorViewTimer()
                .environmentObject(patientMonitorDriver)
            Spacer()
                .frame(height: 16)
            StartStopButton()
                .environmentObject(patientMonitorDriver)
                .environmentObject(dashboardDriver)
                .environmentObject(patientLandingDriver)
            Spacer()
            StartNextPositionButton()
                .environmentObject(patientMonitorDriver)
                .allowsHitTesting(patientMonitorDriver.isWearableConnected)
                .padding(.horizontal, 16)
                .frame(height: 54)
            Spacer()
                .frame(height: 30)
            ComplianceBar()
                .environmentObject(patientMonitorDriver)
        }
    }

    @ViewBuilder
    private var settingsView: some View {
        HStack {
            Spacer()
            Button {
                patientMonitorDriver.showConfig.toggle()
            } label: {
                Image(R.image.componentSettings.name)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func roomNumberView(_ number: String) -> some View {
        HStack {
            Text(R.string.localizable.patientMonitorRoomNumber(number))
                .font(.custom("Avenir-Heavy", size: 16))
                .padding(.top, 85)
                .padding(.leading, 16)
            Spacer()
        }
    }

    @ViewBuilder
    private var configTimerView: some View {
        ConfigTimer(
            timeToTurn: TurnThresholds.timeToTurnThreshold,
            notComplying: TurnThresholds.notComplyingThreshold,
            patchExpiration: patientMonitorDriver.patchExpirationThreshold
        )
        .environmentObject(patientMonitorDriver)
    }
}

struct PatientMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        PatientMonitorView()
            .environmentObject(PatientMonitorDriver(using: PatientManager.preview))
            .environmentObject(PatientLandingDriver())
            .environmentObject(DashboardDriver())
            .environmentObject(AudioAlertPlayer())
    }
}
