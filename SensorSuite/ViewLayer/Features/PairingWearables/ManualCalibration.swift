//
//  ManualCalibration.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 1/26/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct ManualCalibration: View {
    @EnvironmentObject var dashboardDriver: DashboardDriver
    @Binding var pairWearablesFlow: DashboardDriver.PairWearablesModal?
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    @State private var rollAngle = 0.0
    @State private var rollLastAngle = 0.0
    @State private var pitchAngle = 0.0
    @State private var pitchLastAngle = 0.0
    @State private var length: CGFloat = 27
    @State private var calibrated = false
    @State private var shouldHide = false
    @State private var isLoading = true
    @State private var requesting = false
    @State private var showNextViewInFlow = false
    @State private var receivedVa = false
    @State private var showAlert = false
    @State private var retryTimes = 1 // Number of retries (max retries: 3)
    @State private var forceFailed = false
    @State private var shouldShowHeadBedCalibration = false
    @Injected(\.userDefaults) private var userDefaults

    private(set) var wearableId: String?
    var graceTimer = 5 // BLE window in seconds
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
                            if !forceFailed { requestCalibrationPoint() }
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
        ZStack(alignment: .bottom) {
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
                            Button(action: {
                                self.presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(R.image.chevronLeft.name)
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 34, height: 34)
                                    .foregroundColor(.black)
                            }

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

                        Text(!calibrated ? R.string.localizable.pleaseCalibrateWearable() : R.string.localizable.successfullyCalibrated())
                            .font(.custom("Avenir", size: 24))
                            .fontWeight(.heavy)
                    }
                }

                if !shouldHide {
                    VStack(alignment: .center, spacing: 16) {
                        VStack {
                            Text("Head of Bed")
                                .textStyle(.bold)
                                .font(.custom("Avenir", size: 18))
                            HeadOfBedImage(angle: pitchAngle, target: .supine)
                                .frame(height: 275)
                            let displayPitchAngle = Double(pitchAngle.truncatingRemainder(dividingBy: 360.0)).rounded(.up).clean
                            Text(String(displayPitchAngle)
                                .replacingOccurrences(of: "-", with: "") + "\u{00B0}")
                            .transition(.opacity)
                        }
                        .onTapGesture {
                            shouldShowHeadBedCalibration = true
                        }
                        .disabled(requesting || calibrated)
                        Spacer()
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
                }

                VStack {
                    ZStack(alignment: .center) {
                        Button {
                            requesting = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                if !calibrated {
                                    requestCalibrationPoint()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                        if !receivedVa {
                                            showAlert = true
                                        }
                                    }
                                }
                            }
                        } label: {
                            Text(R.string.localizable.confirm())
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 16)
                        .altBtnIndigo()
                        .opacity(calibrated ? 0 : 1)
                        .disabled(requesting || calibrated)

                        Button {
                            pairWearablesFlow = nil
                        } label: {
                            Text(R.string.localizable.continue())
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 16)
                        .altBtnIndigo()
                        .opacity(!calibrated ? 0 : 1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            VStack {
                Spacer()
                Text(DeviceConstants.getBuildInfoStr(facilityName: userDefaults.facilityName))
                    .textStyle(.overline, color: .silver)
                    .multilineTextAlignment(.center)
            }
            if requesting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .aqua))
                    .scaleEffect(2, anchor: .center)
            }

            if shouldShowHeadBedCalibration {
                VStack {
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                .faintingLight.opacity(0),
                                .faintingLight.opacity(0.2),
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom)
                }
                .padding(.top, 0)
            }

            BottomSheetView(isOpen: $shouldShowHeadBedCalibration, maxHeight: 320) {
                CalibrationPickerView(
                    degrees: [Int](0...90),
                    angle: $pitchAngle,
                    lastAngle: $pitchLastAngle,
                    showPickerView: $shouldShowHeadBedCalibration
                )
            }
        }
        .navigationBarHidden(true)
        .onTapGesture {
            self.dismissKeyboard()
        }
        .alert(isPresented: $showAlert) { calibrationErrorAlert }
    }
}

// MARK: - Private
private extension ManualCalibration {
    func dismissKeyboard() {
        shouldHide = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
    
    func requestCalibrationPoint() {
        let rollRadian = (Double.pi * rollAngle) / 180
        let pitchRadian = (Double.pi * pitchAngle) / 180
        dashboardDriver.requestDataLocation(true, wearableId: wearableId!) { result in
            if result {
                var thisWearable: Wearable?
                for wearable in dashboardDriver.connectedWearables where wearable.id.formattedId() == wearableId {
                    thisWearable = wearable
                }
                guard let wearable = thisWearable else { return }
                wearable.calibrationPoint?.rollAttitude = wearable.calibrationPoint!.rollAttitude - rollRadian
                wearable.calibrationPoint?.pitchAttitude = wearable.calibrationPoint!.pitchAttitude - pitchRadian
                isLoading = false
                withAnimation {
                    calibrated = true
                    dashboardDriver.setupFinished = true
                    pairWearablesFlow = nil
                }
            }
            receivedVa = true
        }
    }
}

struct ManualCalibration_Previews: PreviewProvider {
    static var previews: some View {
        ManualCalibration(pairWearablesFlow: .constant(nil),
                          wearableId: "ECFZU7CHZ0")
            .environmentObject(DashboardDriver())
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
