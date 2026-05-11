//
//  ConfigTimer.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 4/13/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ConfigTimer: View {
    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    
    @State var timeToTurn: String
    @State var notComplying: String
    @State var patchExpiration: String
    @State private var showingShare = false

    var body: some View {
        ZStack {
            VStack {
                VStack {
                    HStack {
                        Text("Timer Override")
                            .font(.custom("Avenir-Heavy", size: 24))
                            .foregroundColor(.charcoal3)
                        Spacer()
                        Button {
                            let timeToTurnInt = Int(timeToTurn)
                            let notComplyingInt = Int(notComplying)
                            let patchExpirationInt = Int(patchExpiration)

                            patientMonitorDriver.setTimeToTurnTimer(newThreshold: timeToTurnInt ?? TurnThresholds.timeToTurnThreshold)
                            patientMonitorDriver.setNotComplyingThreshold(newThreshold: notComplyingInt ?? TurnThresholds.notComplyingThreshold)
                            patientMonitorDriver.setPatchExpirationThreshold(newThreshold: patchExpirationInt ?? 96 * 60 * 60)
                            patientMonitorDriver.showConfig = false
                        } label: {
                            Text("Save")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                Spacer()
                InputField("Alert time to turn when ______",
                           placeholder: "Enter",
                           inputTxt: $timeToTurn,
                           requirement: .constant(.remainingSeconds))
                InputField("Alert not complying after ______________",
                           placeholder: "Enter",
                           inputTxt: $notComplying,
                           requirement: .constant(.seconds))
                InputField("Alert patch replacement alert after _____",
                           placeholder: "Enter",
                           inputTxt: $patchExpiration,
                           requirement: .constant(.seconds))
                Spacer()
                Button(action: {
                    self.showingShare = true
                    logger.info("Open Share Sheet")
                }, label: {
                    Text("Export Device Logs")
                })
                Spacer()
                Button(action: {
                    fatalError("Crash was manually triggered")
                }, label: {
                    Text("Generate Crash Exception")
                })
                Spacer()
            }
            .padding()
            .onTapGesture {
                self.dismissKeyboard()
            }
            .sheet(isPresented: $showingShare) {
                if let url = FileLogWriter()?.currentLogFileURL() {
                    ActivityView(activityItems: [url]) {
                        logger.info("Share Sheet Dismissed")
                    }
                }
            }
        }
    }
    
    // MARK: - Init
    init(timeToTurn: Int, notComplying: Int, patchExpiration: Int) {
        _timeToTurn = State(initialValue: String(timeToTurn - 60))
        _notComplying = State(initialValue: String(notComplying))
        _patchExpiration = State(initialValue: String(patchExpiration))
    }
}

// MARK: - Private
private extension ConfigTimer {
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ConfigTimer_Previews: PreviewProvider {
    static var previews: some View {
        ConfigTimer(
            timeToTurn: TurnThresholds.timeToTurnThreshold,
            notComplying: TurnThresholds.notComplyingThreshold,
            patchExpiration: PatientMonitorDriver().patchExpirationThreshold
        )
        .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
        .environmentObject(PatientMonitorDriver())
    }
}
