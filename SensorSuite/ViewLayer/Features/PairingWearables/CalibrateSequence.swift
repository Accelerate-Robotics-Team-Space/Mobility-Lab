//
//  CalibrateSequence.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 10/13/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct CalibrateSequence: View {
    @EnvironmentObject var dashboardDriver: DashboardDriver
    
    @Binding var pairWearablesFlow: DashboardDriver.PairWearablesModal?
    
    @State private var calibrated = false
    @State private var isLoading = true
    @State private var showNextViewInFlow = false
    @State private var showingAlert = false
    @State private var retryTimes = 1 // Number of retries (max retries: 3)
    @State private var receivedVa = false
    @State private var showAlert = false
    @Injected(\.userDefaults) private var userDefaults

    private(set) var wearableId: String?
    var graceTimer = 5 // BLE window
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var alertTitle: String {
        if retryTimes <= 3 {
            return "Something went wrong"
        } else {
            return "App is not responding"
        }
    }
    
    private var alertBody: String {
        if retryTimes <= 3 {
            return "Please try again to calibrate"
        } else {
            return "Terminating...."
        }
    }
    
    private var calibrationErrorAlert: Alert {
        let alertAction = {
            // Dismiss and start again
            showAlert = false
            if retryTimes <= 3 {
                if !receivedVa {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        if !calibrated {
                            requestCalibrationPoint()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                if !receivedVa {
                                    showAlert = true
                                    retryTimes += 1
                                }
                            }
                        }
                    }
                }
            } else if retryTimes > 3 {
                dashboardDriver.unpair()
                pairWearablesFlow = nil
            }
        }
        
        return Alert(title: Text(alertTitle),
                     message: Text(alertBody),
                     dismissButton: .default(R.string.localizable.ok.text,
                                             action: alertAction))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 46) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(!calibrated ? R.image.steps3Of3Percent50.name : R.image.steps3Of3.name)
                            .resizable()
                            .frame(height: 8)
                        Spacer(minLength: 23)
                        Text(R.string.localizable.step3Of3())
                            .font(.custom("Avenir", size: 14))
                            .fontWeight(.light)
                            .foregroundColor(.charcoal3)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text(R.string.localizable.pairWearable())
                                .font(.custom("Avenir", size: 24))
                                .bold()
                                .foregroundColor(.charcoal3)
                            
                            Spacer()
                            
                            Button(action: {
                                pairWearablesFlow = nil
                            }) {
                                Image(R.image.cross.name)
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.charcoal3)
                            }
                            .hidden()
                        }
                        
                        Text(!calibrated ? R.string.localizable.calibrateWearable() : R.string.localizable.successfullyCalibrated())
                            .font(.custom("Avenir", size: 24))
                            .fontWeight(.heavy)
                    }
                }
                
                VStack(alignment: .center, spacing: 16) {
                    ZStack {
                        Image(R.image.watch.name)
                            .resizable()
                            .scaledToFit()
                        Image(!calibrated ? R.image.orangeCircle.name : R.image.tick.name)
                            .resizable()
                            .frame(width: 40, height: 40)
                        if isLoading {
                            ThreeDotsLoading()
                        }
                    }
                    Text(wearableId ?? "?")
                        .font(.custom("SF Compact Text", size: 16))
                        .bold()
                        .foregroundColor(.aqua1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 1000)
                                .stroke(Color.aqua1, lineWidth: 1)
                        )
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .center, spacing: 16) {
                    Button {
                        pairWearablesFlow = nil
                        dashboardDriver.setupFinished = true
                    } label: {
                        Text(R.string.localizable.continue())
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .altBtnIndigo()
                    .opacity(!calibrated ? 0 : 1)
                    .disabled(!calibrated)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            VStack {
                Spacer()
                Text(DeviceConstants.getBuildInfoStr(facilityName: userDefaults.facilityName))
                    .textStyle(.overline, color: .silver)
                    .multilineTextAlignment(.center)
            }
        }
        .navigationBarHidden(true)
        .task {
            guard !receivedVa else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            guard !calibrated else { return }
            requestCalibrationPoint()
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if !receivedVa {
                showAlert = true
            }
        }
        .alert(isPresented: $showAlert) { calibrationErrorAlert }
    }
}

// MARK: - Private
private extension CalibrateSequence {
    func requestCalibrationPoint() {
        dashboardDriver.requestDataLocation(true, wearableId: wearableId!) { result in
            if result {
                isLoading = false
                withAnimation {
                    calibrated = true
                }
            }
            receivedVa = true
        }
    }
}

struct CalibrateSequence_Previews: PreviewProvider {
    static var previews: some View {
        CalibrateSequence(pairWearablesFlow: .constant(nil),
                          wearableId: "ECFZU7CHZ0")
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
