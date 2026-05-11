//
//  BMMCardView.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/24/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BMMCardView: View {
    @ObservedObject var bmmViewModel: BMMViewModel

    var body: some View {
        GeometryReader { geo in
            VStack {
                if bmmViewModel.patientState == .unassigned {
                    BMMCardUnassigned()
                } else if bmmViewModel.patientState == .noSession {
                    BMMCardNoSession(bmmData: bmmViewModel.cardData)
                } else if bmmViewModel.patientState == .ready {
                    BMMCardReady(bmmData: bmmViewModel.cardData)
                } else if bmmViewModel.bmmState == .disconnected {
                    BMMCardDisconnected(bmmData: bmmViewModel.cardData)
                } else if bmmViewModel.cardData.sensorState == .disconnected,
                          bmmViewModel.patientState != .swappingPatch,
                          bmmViewModel.patientState != .swappingSensor {
                    BMMCardDisconnected(bmmData: bmmViewModel.cardData)
                } else if (bmmViewModel.cardData.isLowBatteryCritical
                           || (bmmViewModel.cardData.isLowBatteryWarning && bmmViewModel.cardData.canShowLowBatteryWarningBanner))
							&& bmmViewModel.patientState != .swappingPatch
							&& bmmViewModel.patientState != .swappingSensor
							&& bmmViewModel.patientState != .unassigned
							&& bmmViewModel.patientState != .noSession {
                    BMMCardLowBattery(bmmData: bmmViewModel.cardData)
                } else {
                    BMMCardSwitching(bmmData: bmmViewModel.cardData)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .cornerRadius(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 0)
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 1)
                    .conditionalModifier(
                        bmmViewModel.patientState == .noSession
                        || bmmViewModel.patientState == .ready
                        || bmmViewModel.patientState == .unassigned
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
					) {
						$0.overlay(
							RoundedRectangle(cornerRadius: 16)
								.stroke(Color.red1, lineWidth: 2)
						)
					}
					.conditionalModifier(
                        bmmViewModel.cardData.isLowBatteryWarning
						&& !(
							bmmViewModel.bmmState == .disconnected
                            || bmmViewModel.cardData.sensorState == .disconnected
                            || bmmViewModel.cardData.isLowBatteryCritical
						)
                        && bmmViewModel.cardData.canShowLowBatteryWarningBanner
						&& bmmViewModel.patientState != .noSession
						&& bmmViewModel.patientState != .ready
						&& bmmViewModel.patientState != .unassigned
					) {
						$0.overlay(
							RoundedRectangle(cornerRadius: 16)
								.stroke(Color.yellow1, lineWidth: 2)
						)
					}
                    .conditionalModifier(
                        bmmViewModel.bmmState != .disconnected
                        && bmmViewModel.cardData.sensorState != .disconnected
                        && !bmmViewModel.cardData.isLowBatteryCritical
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
}

struct BMMCardView_Previews: PreviewProvider {
    static var previews: some View {
        BMMCardView(bmmViewModel: BMMViewModel())
    }
}
