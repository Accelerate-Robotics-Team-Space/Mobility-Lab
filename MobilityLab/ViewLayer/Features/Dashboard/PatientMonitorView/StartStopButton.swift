//
//  StartStopButton.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 4/6/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct StartStopButton: View {
    @Injected(\.patchTrackingService) private var patchService: PatchTrackingServiceProtocol
    @Injected(\.userDefaults) private var userDefaults

    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    @EnvironmentObject var dashboardDriver: DashboardDriver
    @EnvironmentObject var patientLandingDriver: PatientLandingDriver

    @State private var pauseReason: PauseReason = .pause
    @State private var showDialog: Bool = false

    var body: some View {
        VStack {
            if patientMonitorDriver.currentState != .onPause && patientMonitorDriver.isWearableConnected {
                if patientMonitorDriver.currentState == .onStart {
                   patientStateButton
                } else {
                    pauseMonitoringButton
                    .presentContent(
						isPresented: $showDialog,
						tag: 26
					) { _ in
                        sheetSelection()
                    }
                    .onChange(of: pauseReason) { pauseReason in
                        handlePauseReasonChange(pauseReason)
                    }
                }
            } else if patientMonitorDriver.currentState == .onPause {
                currentStateButton
            }
        }
        .presentContent(
            isPresented: $patientMonitorDriver.startNextPositionConfirmation,
            tag: 14,
            animated: false,
            content: { _ in
                startNextPositionConfirmation()
            }
        )
        .presentContent(
            isPresented: $patientMonitorDriver.showNextPositionNotAvailable,
            tag: 15,
            animated: true,
            content: { _ in
                nextPositionNotAvailable()
            }
        )
    }

    @ViewBuilder
    private var patientStateButton: some View {
        Button {
            patientMonitorDriver.startTapped()
        } label: {
            Text(patientMonitorDriver.currentState.buttonText)
                .padding(.horizontal, 24)
                .padding(.vertical, 3)
        }
        .altBtnIndigo()
    }

    @ViewBuilder
    private var pauseMonitoringButton: some View {
        VStack {
            Button {
                showDialog = true
            } label: {
                Text("Pause Monitoring")
                    .bold()
                    .font(.custom("Avenir", size: 16))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.indigo1)
        .clipShape(RoundedRectangle(cornerRadius: 2000))
        .overlay(
            RoundedRectangle(cornerRadius: 2000)
                .stroke(Color.indigo1, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var currentStateButton: some View {
        HStack(spacing: 16) {
            Button {
                patientMonitorDriver.currentState = .onResume
                patientMonitorDriver.setTrackingTo(to: true)
            } label: {
                Text(patientMonitorDriver.currentState.buttonText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            }
            .disabled(!patientMonitorDriver.isWearableConnected)
            .buttonStyle(patientMonitorDriver.isWearableConnected
                         ? ALTButtonStyle() : ALTButtonStyle.altBtnIndigoDisabled())
        }
        .padding(.horizontal, 87)
    }

    private func handlePauseReasonChange(_ pauseReason: PauseReason) {
        if pauseReason != .endSession && pauseReason != .pause {
            patientMonitorDriver.currentState = .onPause
            patientMonitorDriver.pauseReason = pauseReason
            patientMonitorDriver.setTrackingTo(to: false)
            if pauseReason == .swappingPatch {
                patientMonitorDriver.swappingPatch()
            } else if pauseReason == .swappingWearable {
                patientMonitorDriver.swapWearable(value: true)
                patientMonitorDriver.resetWrongPositionDetectedAlert()
                patientMonitorDriver.timeToTurn = false
            } else if pauseReason == .surgery {
                patchService.patchUsed()
            }
        }
        self.pauseReason = .pause
    }
}

extension StartStopButton {
    private func sheetSelection() -> some View {
        Rectangle().buildSheet {
            Text("Pause Reason")
                .textStyle(.bold, color: .charcoal1)
                .frame(height: 36)
        } bodyContent: {
            button(for: .swappingWearable)
            button(for: .physicalTherapy)
            button(for: .patientInChair)
            button(for: .outOfBedMobility)
            button(for: .swappingPatch)
            button(for: .caregiverRequest)
            button(for: .surgery)
            button(for: .patientRequest)
            button(for: .sleep)
        } cancelContent: {
            Text("Cancel")
                .textStyle(.body, color: .red1)
                .dialogAction {
                    showDialog = false
                }
        }
    }

    private func startNextPositionConfirmation() -> some View {
        AlertCardView(
            title: R.string.localizable.startNextPosition(patientMonitorDriver.nextDesiredPosition.description),
            msg: R.string.localizable.startNextPositionConfirmation(),
            secondaryButtonString: R.string.localizable.cancel(),
            secondaryButtonAction: { patientMonitorDriver.startNextPositionConfirmation = false },
            primaryButtonString: R.string.localizable.startNow(),
            primaryButtonAction: patientMonitorDriver.startNextPosition
        )
        .frame(maxWidth: 280)
    }

    private func nextPositionNotAvailable() -> some View {
        CardViewWithButton(
            title: R.string.localizable.warning(),
            msg: R.string.localizable.positionChangeNotAllowed(userDefaults.turnProtocol!.hours),
            buttonTitle: R.string.localizable.ok().uppercased()
        ) {
            patientMonitorDriver.showNextPositionNotAvailable = false
        }
        .frame(maxWidth: 280)
    }

    private func button(for reason: PauseReason) -> DialogButton<some View> {
        Text(reason.rawValue)
            .textStyle(.body, color: .indigo1)
            .dialogAction {
                pauseReason = reason
                showDialog = false
            }
    }
}

private extension TurnProtocol {
    var hours: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        let string = formatter.string(from: NSNumber(value: duration / TimeInterval.secondsPerHour)) ?? "unknown"
        return string.lowercased()
    }
}

struct StartStopButton_Previews: PreviewProvider {
    static var previews: some View {
        StartStopButton()
            .environmentObject(PatientMonitorDriver())
            .environmentObject(DashboardDriver())
            .environmentObject(PatientLandingDriver())
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
