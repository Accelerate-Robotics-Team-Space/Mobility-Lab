//
//  BMMDetailsSessionStateView.swift
//  SensorSuite UMM
//
//  Created by Vadym Riznychok on 11/29/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BMMDetailsSessionStateView: View {
    @ObservedObject var bmmViewModel: BMMViewModel
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack {
            Text(sessionState)
                .textCase(.uppercase)
                .font(.custom("Avenir-Heavy", size: 14))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .capsuleCard(alertLevel: bmmViewModel.currentAlert)
            VStack {
                if bmmViewModel.patientState == .swappingPatch || bmmViewModel.patientState == .swappingSensor {
                    Text("+" + bmmViewModel.cardData.swappingTimeStr)
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(bmmViewModel.currentAlert.primaryTextColor)
                } else if bmmViewModel.patientState == .paused {
           
                    Text(bmmViewModel.cardData.pausedTimeStr)
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(
                            (bmmViewModel.bmmState == .disconnected) ||
                            (bmmViewModel.cardData.sensorState == .disconnected &&
                             bmmViewModel.patientState != .swappingPatch &&
                             bmmViewModel.patientState != .swappingSensor)
                            ? .red1
                            : bmmViewModel.currentAlert.primaryTextColor
                        )
                } else if bmmViewModel.cardData.canShowPatientDetails {
                    if bmmViewModel.cardData.sensorState == .disconnected,
                       bmmViewModel.patientState != .swappingPatch,
                       bmmViewModel.patientState != .swappingSensor {
                        Text("+" + bmmViewModel.cardData.disconnectedTimeStr)
                            .font(.custom("Avenir-Heavy", size: 20))
                            .foregroundColor(.red1)
                    } else {
                        Text("+" + bmmViewModel.cardData.timeRemainingStr)
                            .font(.custom("Avenir-Heavy", size: 20))
                            .foregroundColor(bmmViewModel.isOverdue ? .red1 : .clear)
                    }
                }
                VStack {}
                    .frame(height: 4)
            }
            HStack {
                VStack {
                    Text("TOTAL MONITORED TIME")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(.charcoal4)
                    Text(bmmViewModel.cardData.canShowPatientDetails ? bmmViewModel.analyticsData.totalMonitoringDuration() : "00:00:00" )
                        .font(.custom("Avenir-Heavy", size: 24))
                        .foregroundColor(.charcoal1)
                }
                Spacer()
                VStack {
                    Text("REMAINING TIME IN CURRENT POSITION")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(.charcoal4)
                    Text(
                        (selectedDate.isToday
                         && bmmViewModel.cardData.canShowPatientDetails
                         && !bmmViewModel.isOverdue)
                        ? bmmViewModel.cardData.positionalTimeRemainingStr 
                        : "00:00:00"
                    )
                        .font(.custom("Avenir-Heavy", size: 24))
                        .foregroundColor(.charcoal1)
                }
                Spacer()
                VStack {
                    Text("Daily Turn Effectiveness")
                        .textCase(.uppercase)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(.charcoal4)
                    Text(bmmViewModel.cardData.canShowPatientDetails ? bmmViewModel.analyticsData.complianceStr : " ")
                        .font(.custom("Avenir-Heavy", size: 24))
                        .foregroundColor(.charcoal1)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var sessionState: String {
        var state = bmmViewModel.patientState?.toString().uppercased() ?? ""
        guard ![.unassigned, .noSession, .ready].contains(bmmViewModel.patientState) else {
            return state
        }
        if bmmViewModel.patientState == .paused ||
           bmmViewModel.patientState == .swappingPatch ||
           bmmViewModel.patientState == .swappingSensor {
            state = "PAUSED: \(bmmViewModel.bmmPauseReason)"
        } else if (bmmViewModel.bmmState == .disconnected) ||
                    (bmmViewModel.cardData.sensorState == .disconnected &&
                     bmmViewModel.patientState != .swappingPatch &&
                     bmmViewModel.patientState != .swappingSensor) {
            state = "LOST SIGNAL"
        } else if bmmViewModel.cardData.isLowBatteryCritical &&
                    bmmViewModel.patientState != .swappingPatch &&
                    bmmViewModel.patientState != .swappingSensor &&
                    bmmViewModel.patientState != .unassigned &&
                    bmmViewModel.patientState != .noSession {
            state = "LOW BATTERY"
        } else if bmmViewModel.cardData.isLowBatteryWarning && bmmViewModel.cardData.canShowLowBatteryWarningBanner {
			state = "LOW BATTERY"
		}

        return state
    }
}

struct BMMDetailsSessionStateView_Previews: PreviewProvider {
    static var previews: some View {
        BMMDetailsSessionStateView(bmmViewModel: BMMViewModel(), selectedDate: .constant(Date()))
    }
}
