//
//  PatientMonitorAlertQueue.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 4/6/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PatientMonitorAlertQueue: View {
    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    @EnvironmentObject var audioAlertPlayer: AudioAlertPlayer

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(patientMonitorDriver.alertQueue, id: \.self) { alert in
                switch alert {
                case .wrongPosition:
                    wrongPositionCard
                case .timeToTurn(let nextPosition):
                    timeToTurnCard(nextPosition: nextPosition)
                case .sensorLowBattery:
                    sensorLowBatteryCard
                case .patchExpired:
                    if patientMonitorDriver.displayPatchExpiredAlert {
                        patchExpiredCard
                    }
                case .sensorDisconnect:
                    sensorDisconnectCard
                case .sensorDisconnectOver1Hour:
                    sensorDisconnectOver1HourCard
                case .longSwapPeriod:
                    longSwapCard
                case .longPausePeriod:
                    longPauseCard
                case .rePairSensor:
                    rePairSensorCard
                }
            }
            if patientMonitorDriver.alertQueue.count > 1 {
                HStack {
                    ZStack(alignment: .center) {
                        Circle()
                            .stroke(.white, lineWidth: 1)
                            .background(Circle().fill(Color.red1))
                            .frame(width: 20, height: 20)
                        Text("\(patientMonitorDriver.alertQueue.count)")
                            .font(.custom("Avenir-Roman", size: 14))
                            .foregroundColor(.white)
                    }
                    .offset(x: -10, y: -10)
                    Spacer()
                    Button {
                        withAnimation {
                            patientMonitorDriver.sendAlertToBack()
                        }
                    } label: {
                        Image(R.image.rotate.name)
                            .resizable()
                    }
                    .frame(width: 25, height: 25)
                    .offset(x: -5, y: 5)
                }
            }
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private var wrongPositionCard: some View {
        CardViewWithButton(
            title: R.string.localizable.wrongPositionDetected(),
            msg: R.string.localizable.wearableDetectedWrongPositionOver(),
            buttonTitle: R.string.localizable.dismiss(),
            buttonAction: {
                patientMonitorDriver.resetWrongPositionDetectedAlert()
            }
        )
        .onAppear {
            guard patientMonitorDriver.alertQueue.count == 1 else { return }
            audioAlertPlayer.playWrongPosition()
        }
        .onChange(of: $patientMonitorDriver.alertQueue.count) { newCount in
            if newCount == 1 && !patientMonitorDriver.isComplying {
                audioAlertPlayer.playWrongPosition()
            }
        }
    }

    @ViewBuilder
    private func timeToTurnCard(nextPosition: PositionalFlagCategory) -> some View {
        CardViewWithButton(
            title: R.string.localizable.timeToTurnYourPatient(),
            msg: R.string.localizable.itThatTimeToTurn(nextPosition.description),
            buttonTitle: R.string.localizable.dismiss(),
            buttonAction: {
                patientMonitorDriver.resetTimeToTurnAlert()
            }
        )
        .onAppear {
            guard patientMonitorDriver.alertQueue.count == 1 else { return }
            audioAlertPlayer.playTimeToTurn()
        }
        .onChange(of: $patientMonitorDriver.alertQueue.count) { newCount in
            if newCount == 1 && patientMonitorDriver.timeToTurn {
                audioAlertPlayer.playTimeToTurn()
            }
        }
    }

    @ViewBuilder
    private var sensorLowBatteryCard: some View {
        CardViewWithButton(
            title: "Low Battery",
            msg: "Your sensor is low on battery. Please swap and charge",
            buttonTitle: R.string.localizable.dismiss(),
            buttonAction: {
                patientMonitorDriver.resetLowBatteryAlert()
            }
        )
        .onAppear {
            guard patientMonitorDriver.alertQueue.count == 1 else { return }
            audioAlertPlayer.playWearableLowBattery()
        }
        .onChange(of: $patientMonitorDriver.alertQueue.count) { newCount in
            if newCount == 1 && patientMonitorDriver.lowBattery {
                audioAlertPlayer.playWearableLowBattery()
            }
        }
    }

    @ViewBuilder
    private var patchExpiredCard: some View {
        VStack {
            CardViewWith2Buttons(
                title: "Your patch has expired",
                msg: "It's that time again. Please change the patch on your patient",
                secondaryButtonString: "Continue Without Changing",
                secondaryButtonAction: { patientMonitorDriver.retainingPatchAlert = true },
                primaryButtonString: "Swap Patch",
                primaryButtonAction: {
                    patientMonitorDriver.swappingPatch()
                }
            )
            VStack {}
                .frame(height: 24)
            if patientMonitorDriver.retainingPatchAlert {
                altCard(
                    title: R.string.localizable.acknowledgementTitle(),
                    message: R.string.localizable.retainPatchAlertMsg(),
                    buttonText: "Acknowledge"
                ) {
                    patientMonitorDriver.resetPatchTimer()
                    patientMonitorDriver.retainingPatchAlert = false
                }
            }
        }
    }

    @ViewBuilder
    private var sensorDisconnectCard: some View {
        CardViewWithButton(
            title: "Sensor Disconnect",
            msg: "No sensor detected. Pausing your session now",
            buttonTitle: R.string.localizable.dismiss(),
            buttonAction: {
                patientMonitorDriver.resetWearableDisconnectedAlert()
            }
        )
    }

    @ViewBuilder
    private var sensorDisconnectOver1HourCard: some View {
        CardViewWithButton(
            title: "Sensor Disconnect",
            msg: "Paused due to sensor disconnection",
            buttonTitle: R.string.localizable.dismiss(),
            buttonAction: {
                patientMonitorDriver.resetWearableDisconnectedAlert()
            }
        )
    }

    @ViewBuilder
    private var longSwapCard: some View {
        CardViewWithButton(
            title: "Are you still swapping?",
            msg: "If not monitoring for an extended period of time, please pause active monitoring session.",
            buttonTitle: R.string.localizable.dismiss(),
            buttonAction: { patientMonitorDriver.resetOverdueSwappingAlert() }
        )
    }

    @ViewBuilder
    private var longPauseCard: some View {
        CardViewWithButton(
            title: "Are you still paused?",
            msg: "Don't forget to start monitoring when it is possible.",
            buttonTitle: R.string.localizable.dismiss(),
            buttonAction: { patientMonitorDriver.resetPauseTimer() }
        )
    }

    @ViewBuilder
    private var rePairSensorCard: some View {
        CardViewWithButton(
            title: "Connection Disrupted",
            msg: "Please re-pair sensor to resume session",
            buttonTitle: R.string.localizable.dismiss()
        ) {
            patientMonitorDriver.resetRePairWearableAlert()
        }
    }

    @ViewBuilder
    private func altCard(
        title: String,
        message: String,
        buttonText: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack {
            Text(title)
                .textCase(.uppercase)
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.charcoal1)
                .padding(.top, 12)
                .padding(.bottom, 4)
            Text(message)
                .font(.custom("Avenir-Roman", size: 16))
                .foregroundColor(.charcoal1)
                .padding(.horizontal, 16)
            Divider()
            Button {
                action()
            } label: {
                Text(buttonText)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.indigo1)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
    }
}

struct PatientMonitorAlertQueue_Previews: PreviewProvider {
    static var previews: some View {
        PatientMonitorAlertQueue()
            .environmentObject(PatientMonitorDriver())
            .environmentObject(AudioAlertPlayer())
    }
}
