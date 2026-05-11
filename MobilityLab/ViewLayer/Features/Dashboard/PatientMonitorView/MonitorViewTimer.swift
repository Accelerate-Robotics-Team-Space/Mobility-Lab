//
//  MonitorViewTimer.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 4/5/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct MonitorViewTimer: View {
    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    @Injected(\.userDefaults) private var userDefaults

    private let diffFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()

    var body: some View {
        VStack(spacing: 1) {
            if patientMonitorDriver.currentState != .onStart {
                Text(patientMonitorDriver.statusText)
                    .font(.custom("Avenir-Heavy", size: 15))
                    .padding(EdgeInsets(top: 5, leading: 7, bottom: 5, trailing: 7))
                    .foregroundColor(patientMonitorDriver.currentState.textForegroundColor)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 1000)
                            .fill(patientMonitorDriver.currentState.textBackgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 1000)
                            .stroke(patientMonitorDriver.currentState.textBorderColor, lineWidth: 2)
                    )
                    .padding(.top, 3)
                    .padding(.bottom, 12)
            }

            if patientMonitorDriver.currentState == .onStart {
                Text(R.string.localizable.movePatientIntoPosition())
                    .bold()
                    .font(.custom("Avernir", size: 20))
                    .foregroundColor(.charcoal1)
                    .opacity(0.7)
            } else {
                switch patientMonitorDriver.textMode {
                case .paused:
                    Text(patientMonitorDriver.pausedTimeStr)
                        .font(.custom("Avernir-Heavy", size: 20))
                        .foregroundColor(patientMonitorDriver.pausedTextColor)
                        .opacity(0.7)
                case .countdown:
                    Text(patientMonitorDriver.countdownStr)
                        .font(.custom("Avernir-Heavy", size: 20))
                        .foregroundColor(!patientMonitorDriver.isCountdownNeg ? .charcoal1 : .red1)
                        .opacity(0.7)

                    #if DEV || QA
                    // Debug Builds Only
                    if patientMonitorDriver.showDebugTimers {
                        HStack(spacing: 6) {
                            Text(Duration.seconds(patientMonitorDriver.timeInTurn), format: .time(pattern: .hourMinuteSecond))
                                .font(.custom("Avernir", size: 18))
                                .foregroundColor(.charcoal1)
                            Text("Time In Turn")
                                .font(.custom("Avernir", size: 15))
                                .foregroundColor(.charcoal1)
                        }
                        
                        HStack(spacing: 6) {
                            Text(
                                Duration.seconds(userDefaults.turnProtocol!.duration - patientMonitorDriver.timeInTurn),
                                format: .time(pattern: .hourMinuteSecond)
                            )
                            .font(.custom("Avernir", size: 18))
                            .foregroundColor(.charcoal1)

                            Text("Auto-Turn")
                                .font(.custom("Avernir", size: 15))
                                .foregroundColor(.charcoal1)
                        }
                        
                        if patientMonitorDriver.diff.magnitude > 10 {
                            Rectangle().fill(.clear).frame(height: 5)
                            
                            VStack(spacing: 2) {
                                Text("Difference (remaining - autoTurn):")
                                    .font(.custom("Avernir", size: 15))
                                    .foregroundColor(.charcoal1)
                                Text(diffFormatter.string(from: patientMonitorDriver.diff) ?? "00:00:00")
                                    .font(.custom("Avernir", size: 18))
                                    .foregroundColor(.charcoal1)
                            }
                        }
                    }
                    #endif
                }
            }
        }
    }
}

private extension PatientMonitorState {
    var textForegroundColor: Color {
        switch self {
        case .onResume:
            return .green1
        default:
            return .charcoal3
        }
    }

    var textBackgroundColor: Color {
        switch self {
        case .onResume:
            return .green5
        default:
            return .ash
        }
    }

    var textBorderColor: Color {
        switch self {
        case .onResume:
            return .green2
        default:
            return .charcoal3
        }
    }
}

private extension PatientMonitorDriver {
    var pausedTextColor: Color {
        switch pauseReason {
        case .crash, .disconnected:
            return .red1
        default:
            return .indigo1
        }
    }
}

struct MonitorViewTimer_Previews: PreviewProvider {
    static var previews: some View {
        MonitorViewTimer()
            .environmentObject(PatientMonitorDriver())
    }
}
