//
//  BMMListView.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 11/8/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BMMListView: View {
    @ObservedObject var bmmViewModel: BMMViewModel

    var body: some View {
        HStack {
            if bmmViewModel.patientState == .unassigned {
                Text("UNASSIGNED")
                    .font(.custom("Avenir-Roman", size: 10))
                    .frame(width: 71, alignment: .leading)
            } else {
                Text(bmmViewModel.roomBed ?? "Unknown")
                    .font(.custom("Avenir-Roman", size: bmmViewModel.roomBed == "UNASSIGNED" ? 10 : 16))
                    .frame(width: 71, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if bmmViewModel.patientState == .noSession {
                        Text("NO SESSION")
                            .font(.custom("Avenir-Roman", size: 12))
                            .capsuleCard(.standby)
                            .frame(maxWidth: 143, alignment: .leading)
                        Text("No active patient session")
                            .font(.custom("Avenir-Roman", size: 14))
                            .frame(maxWidth: 220, alignment: .leading)
                            .foregroundColor(.charcoal1)
                    } else if bmmViewModel.patientState == .ready {
                        Text("READY")
                            .font(.custom("Avenir-Roman", size: 12))
                            .capsuleCard(.standby)
                            .frame(maxWidth: 143, alignment: .leading)
                        if let room = bmmViewModel.cardData.lastSeen?.roomBedNumber, !room.isEmpty {
                            Text("Last seen in \(room)")
                                .font(.custom("Avenir-Roman", size: 14))
                                .frame(maxWidth: 220, alignment: .leading)
                                .foregroundColor(.charcoal1)
                        } else {
                            Text("No active patient session")
                                .font(.custom("Avenir-Roman", size: 14))
                                .frame(maxWidth: 220, alignment: .leading)
                                .foregroundColor(.charcoal1)
                        }
                    } else if bmmViewModel.patientState == .unassigned {
                        Text("UNASSIGNED")
                            .font(.custom("Avenir-Roman", size: 12))
                            .capsuleCard(.standby)
                            .frame(maxWidth: 143, alignment: .leading)
                        Text("Unknown location")
                            .font(.custom("Avenir-Roman", size: 14))
                            .frame(maxWidth: 220, alignment: .leading)
                            .foregroundColor(.charcoal1)
                    } else if bmmViewModel.bmmState == .disconnected {
                        Text("LOST SIGNAL")
                            .font(.custom("Avenir-Roman", size: 12))
                            .capsuleCard(.destructive)
                            .frame(maxWidth: 143, alignment: .leading)
                        Text("+\(bmmViewModel.cardData.disconnectedTimeStr + " bmm has lost signal")")
                            .font(.custom("Avenir-Roman", size: 14))
                            .frame(maxWidth: 220, alignment: .leading)
                            .foregroundColor(.red1)
                    } else if bmmViewModel.cardData.sensorState == .disconnected,
                              bmmViewModel.patientState != .swappingPatch,
                              bmmViewModel.patientState != .swappingSensor {
                        Text("LOST SIGNAL")
                            .font(.custom("Avenir-Roman", size: 12))
                            .capsuleCard(.destructive)
                            .frame(maxWidth: 143, alignment: .leading)
                        Text("+\(bmmViewModel.cardData.disconnectedTimeStr + " sensor has lost signal")")
                            .font(.custom("Avenir-Roman", size: 14))
                            .frame(maxWidth: 220, alignment: .leading)
                            .foregroundColor(.red1)
                    } else if (bmmViewModel.cardData.isLowBatteryCritical
                               || (bmmViewModel.cardData.isLowBatteryWarning && bmmViewModel.cardData.canShowLowBatteryWarningBanner))
                                && bmmViewModel.patientState != .swappingPatch
                                && bmmViewModel.patientState != .swappingSensor
                                && bmmViewModel.patientState != .unassigned
                                && bmmViewModel.patientState != .ready
                                && bmmViewModel.patientState != .noSession {
                        Text("LOW BATTERY")
                            .font(.custom("Avenir-Roman", size: 12))
                            .capsuleCard(bmmViewModel.cardData.isLowBatteryCritical ? .destructive : .warning)
                            .frame(maxWidth: 143, alignment: .leading)
                        if bmmViewModel.isOverdue {
                            Text("+" + bmmViewModel.cardData.timeRemainingStr + " overdue")
                                .font(.custom("Avenir-Roman", size: 14))
                                .foregroundColor(bmmViewModel.timeRemainingAlertColor)
                                .frame(maxWidth: 220, alignment: .leading)
                        } else {
                            Text(bmmViewModel.cardData.timeRemainingStr + " remaining")
                                .font(.custom("Avenir-Roman", size: 14))
                                .frame(maxWidth: 220, alignment: .leading)
                                .foregroundColor(bmmViewModel.timeRemainingAlertColor)
                        }
                    } else {
                        Text(bmmViewModel.patientState?.toString().uppercased() ?? "Unknown")
                            .font(.custom("Avenir-Roman", size: 12))
                            .conditionalModifier(bmmViewModel.patientState != .swappingPatch && bmmViewModel.patientState != .swappingSensor) {
                                $0.capsuleCard(alertLevel: bmmViewModel.currentAlert)
                            }
                            .conditionalModifier(bmmViewModel.patientState == .swappingPatch || bmmViewModel.patientState == .swappingSensor) {
                                $0.capsuleCard(.action)
                            }
                            .frame(maxWidth: 143, alignment: .leading)

                        if bmmViewModel.patientState != .swappingPatch
                            && bmmViewModel.patientState != .swappingSensor
                            && bmmViewModel.cardData.sensorState != .disconnected {
                            if bmmViewModel.patientState == .unassigned {
                                Text("0min remaining")
                                    .font(.custom("Avenir-Roman", size: 14))
                                    .frame(maxWidth: 220, alignment: .leading)
                                    .foregroundColor(bmmViewModel.timeRemainingAlertColor)
                            } else {
                                if bmmViewModel.isOverdue {
                                    Text("+" + bmmViewModel.cardData.timeRemainingStr + " overdue")
                                        .font(.custom("Avenir-Roman", size: 14))
                                        .foregroundColor(bmmViewModel.timeRemainingAlertColor)
                                        .frame(maxWidth: 220, alignment: .leading)
                                } else if bmmViewModel.patientState == .paused {
                                    Text(bmmViewModel.cardData.pausedTimeStr)
                                        .font(.custom("Avenir-Roman", size: 14))
                                        .frame(maxWidth: 220, alignment: .leading)
                                        .foregroundColor(bmmViewModel.timeRemainingAlertColor)
                                } else {
                                    Text(bmmViewModel.cardData.timeRemainingStr + " remaining")
                                        .font(.custom("Avenir-Roman", size: 14))
                                        .frame(maxWidth: 220, alignment: .leading)
                                        .foregroundColor(bmmViewModel.timeRemainingAlertColor)
                                }
                            }
                        } else {
                            if bmmViewModel.patientState == .swappingSensor || bmmViewModel.patientState == .swappingPatch {
                                Text("+\(bmmViewModel.cardData.swappingTimeStr + " \(bmmViewModel.cardData.swappingType)")")
                                    .font(.custom("Avenir-Roman", size: 14))
                                    .frame(maxWidth: 220, alignment: .leading)
                                    .foregroundColor(bmmViewModel.currentAlert.primaryTextColor)
                            } else if bmmViewModel.isOverdue {
                                Text("+" + bmmViewModel.cardData.timeRemainingStr + " overdue")
                                    .font(.custom("Avenir-Roman", size: 14))
                                    .foregroundColor(bmmViewModel.timeRemainingAlertColor)
                                    .frame(maxWidth: 220, alignment: .leading)
                            }
                        }
                    }
                    Spacer()
                    CurrentTargetNextCombo(bmmData: bmmViewModel.cardData)
                        .frame(width: 172)
                        .opacity(bmmViewModel.patientState == .unassigned || bmmViewModel.patientState == .noSession ||
                                 bmmViewModel.patientState == .ready ? 0 : 1)
                        .grayscale(bmmViewModel.cardData.shouldGrayOut ? 0.99 : 0)
                    Spacer()
                        .frame(width: 24)
                    RollPitchVisualizationsListView(bmmData: bmmViewModel.cardData,
                                                    rollDegree: bmmViewModel.cardData.rollAngle,
                                                    pitchDegree: bmmViewModel.cardData.pitchAngle)
                    .frame(width: 115)
                    .opacity(bmmViewModel.patientState == .unassigned || bmmViewModel.patientState == .noSession ? 0 : 1)
                    .grayscale(bmmViewModel.cardData.shouldGrayOut ? 0.99 : 0)
                }
                if bmmViewModel.cardData.isLowBatteryCritical || bmmViewModel.cardData.isLowBatteryWarning {
                    Divider()
                    HStack {
                        BatteryCapacityView(isAlive: bmmViewModel.cardData.isAlive,
                                            bmmBatteryPercentage: bmmViewModel.batteryPercentage,
                                            sensorBatteryPercentage: bmmViewModel.currentWearable?.batteryPercentage,
                                            isStatic: bmmViewModel.isStatic,
                                            bmmBatteryTimeRemaining: bmmViewModel.bmmBatteryTimeRemaining)
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding([.top, .bottom], 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 0)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 1)
                .conditionalModifier(
                    bmmViewModel.patientState == .noSession
                    || bmmViewModel.patientState == .unassigned
                    || bmmViewModel.patientState == .ready
                ) {
                    $0.overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.charcoal1, lineWidth: 2)
                    )
                }
                .conditionalModifier(
                    (
                        bmmViewModel.bmmState == .disconnected
                        || bmmViewModel.cardData.sensorState == .disconnected
                        || bmmViewModel.cardData.isLowBatteryCritical
                    )
                    && bmmViewModel.patientState != .noSession
                    && bmmViewModel.patientState != .ready
                    && bmmViewModel.patientState != .unassigned
                    && bmmViewModel.patientState != .swappingPatch
                    && bmmViewModel.patientState != .swappingSensor
                ) {
                    $0.overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red1, lineWidth: 2)
                    )
                }
                .conditionalModifier(
                    !(
                        bmmViewModel.bmmState == .disconnected
                        || bmmViewModel.cardData.sensorState == .disconnected
                        || bmmViewModel.cardData.isLowBatteryCritical
                    )
                    && bmmViewModel.cardData.isLowBatteryWarning
                    && bmmViewModel.cardData.canShowLowBatteryWarningBanner
                    && bmmViewModel.patientState != .noSession
                    && bmmViewModel.patientState != .ready
                    && bmmViewModel.patientState != .unassigned
                    && bmmViewModel.patientState != .swappingPatch
                    && bmmViewModel.patientState != .swappingSensor
                ) {
                    $0.overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow1, lineWidth: 2)
                    )
                }
                .conditionalModifier(
                    bmmViewModel.bmmState != .disconnected
                    && bmmViewModel.cardData.sensorState != .disconnected
                    && !(bmmViewModel.cardData.isLowBatteryCritical)
                ) {
                    $0.overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(bmmViewModel.currentAlert.borderColor, lineWidth: 2)
                    )
                }
                .conditionalModifier(
                    (bmmViewModel.patientState == .swappingPatch
                     || bmmViewModel.patientState == .swappingSensor)
                    && bmmViewModel.bmmState != .disconnected
                ) {
                    $0.overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.aqua1, lineWidth: 2)
                    )
                }
        )
    }
}

struct BMMListView_Previews: PreviewProvider {
    static var previews: some View {
        BMMListView(bmmViewModel: BMMViewModel())
    }
}
