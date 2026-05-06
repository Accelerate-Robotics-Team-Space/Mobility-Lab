//
//  PatientEndingView.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 9/27/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct PatientEndingView: View {
    @ObservedObject var patientLandingDriver: PatientLandingDriver
    @Binding var patientFlow: PatientLandingDriver.ActiveModal?
    @Binding private var showView: Bool
    
    @State private var showNextViewInFlow = false

    @Injected(\.userDefaults) private var userDefaults

    private let patientManager: PatientManagerProtocol
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 0, green: 0, blue: 0, opacity: 0.1))
                
                VStack(alignment: .center) {
                    stepView
                    VStack(alignment: .leading) {
                        HStack {
                            if patientFlow != nil {
                                addAPatientView
                            }
                            Spacer()
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            successfullyAddedView
                            readyToMonitorView
                        }
                    }

                    Spacer()
                    
                    endingBackground

                    Spacer()
                    
                    doneButton
                    .padding(.bottom, geo.safeAreaInsets.bottom)
                }
                .navigationBarHidden(true)
                .padding()
                .background(background)
                
                VStack {
                    Spacer()
                    buildInfoText
                        .padding(.bottom, geo.safeAreaInsets.bottom)
                }
            }
            .padding(.bottom, -geo.safeAreaInsets.bottom)
            .background(Color.white.opacity(0.1))
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Init
    init(
        patientLandingDriver: PatientLandingDriver,
        showView: Binding<Bool>,
        patientManager: PatientManagerProtocol? = nil,
        flow: Binding<PatientLandingDriver.ActiveModal?> = .constant(nil)
    ) {
        self.patientLandingDriver = patientLandingDriver
        self._patientFlow = flow
        self._showView = showView
        self.patientManager = patientManager ?? Container.shared.patientManager.resolve()
    }
    
    fileprivate init() {
        self.patientLandingDriver = PatientLandingDriver()
        self._patientFlow = .constant(nil)
        self._showView = .constant(true)
        self.patientManager = PatientManager.preview
    }
}

// MARK: - Private
private extension PatientEndingView {
    @ViewBuilder
    var stepView: some View {
        HStack {
            Image(R.image.steps4Of4.name)
                .resizable()
                .frame(height: 8)
            Spacer(minLength: 23)
            Text(R.string.localizable.step4Of4())
                .font(.custom("Avenir", size: 14))
                .fontWeight(.light)
                .foregroundColor(.charcoal3)
        }
    }

    @ViewBuilder
    var addAPatientView: some View {
        Text(R.string.localizable.addAPatient())
            .font(.custom("Avenir", size: 24))
            .bold()
            .foregroundColor(.charcoal3)
    }

    @ViewBuilder
    var successfullyAddedView: some View {
        Text(R.string.localizable.patientAddedSuccessfully())
            .textStyle(.header3, color: .charcoal1)
            .padding(.trailing, 64)
    }

    @ViewBuilder
    var readyToMonitorView: some View {
        Text(R.string.localizable.patientReadyToBeMonitored())
            .textStyle(.body, color: .charcoal1)
            .font(.custom("Avenir", size: 16))
    }

    @ViewBuilder
    var endingBackground: some View {
        VStack {
            Image(R.image.patientEndingBackground.name)
                .resizable()
                .scaledToFit()
        }
    }

    @ViewBuilder
    var buildInfoText: some View {
        Text(DeviceConstants.getBuildInfoStr(facilityName: userDefaults.facilityName))
            .textStyle(.overline, color: .silver)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    var doneButton: some View {
        Button(action: {
            showNextViewInFlow.toggle()
            patientLandingDriver.currentScreen = .dashboard
            withAnimation {
                dismiss()
            }
        }, label: {
            Text(R.string.localizable.done())
                .frame(maxWidth: .infinity)
        })
        .altBtnIndigo()
    }

    @ViewBuilder
    var background: some View {
        Rectangle()
            .fill(Color.white)
            .cornerRadius(24, corners: [.topLeft, .topRight])
            .shadow(
                color: Color(red: 0, green: 0, blue: 0, opacity: 0.1),
                radius: 2,
                x: 0,
                y: 0
            )
    }

    func dismiss() {
        if patientFlow != nil {
            patientFlow = nil
        } else {
            showView = false
        }
    }
}

// MARK: - Preview
struct PatientEndingView_Previews: PreviewProvider {
    static var previews: some View {
        PatientEndingView()
    }
}
