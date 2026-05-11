//
//  StartNextPositionButton.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 4/6/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct StartNextPositionButton: View {
    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    
    var body: some View {
        if patientMonitorDriver.currentState != .onStart, patientMonitorDriver.isWearableConnected {
            // Start next position Button
            Button {
                // Do not display confirmation when time remaining <= 10 mins
                if !patientMonitorDriver.shouldShowStartNextPositionConfirmation {
                    patientMonitorDriver.startNextPosition()
                } // Show alert if position changed too quickly
                else if !patientMonitorDriver.canMoveToNextPosition {
                    patientMonitorDriver.showNextPositionNotAvailable = true
                } // Display confirmation when time remaining > 10 mins
                else {
                    patientMonitorDriver.startNextPositionConfirmation = true
                }
            } label: {
                buttonLabel
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(background)
            .disabled(patientMonitorDriver.currentState == .onPause)
        } else if !patientMonitorDriver.isWearableConnected {
            if patientMonitorDriver.pauseReason == .swappingPatch || patientMonitorDriver.pauseReason == .swappingWearable {
                swapInProgressView
            }
        }
    }

    @ViewBuilder
    private var buttonLabel: some View {
        HStack {
            Image(patientMonitorDriver.nextDesiredPosition.imageStr)
                .resizable()
                .frame(width: 48, height: 12.87)
                .grayscale(patientMonitorDriver.currentState == .onPause ? 0.99 : 0.0)
            Spacer()
            VStack(alignment: .leading) {
                Text(R.string.localizable.next())
                    .font(.custom("Avenir", size: 16))
                    .bold()
                    .foregroundColor(.charcoal)
                Text(patientMonitorDriver.nextDesiredPosition.description)
                    .font(.custom("Avenir", size: 16))
                    .foregroundColor(.charcoal3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            HStack {
                Text(R.string.localizable.startNow())
                    .font(.custom("Avenir", size: 16))
                    .bold()
                    .foregroundColor(patientMonitorDriver.currentState == .onPause ? .charcoal3 : .aqua1)
                Image(R.image.arrowRight.name)
                    .renderingMode(.template)
                    .foregroundColor(patientMonitorDriver.currentState == .onPause ? .charcoal3 : .aqua1)
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    @ViewBuilder
    private var swapInProgressView: some View {
        Text(patientMonitorDriver.pauseReason == .swappingPatch ? "Replacing in Progress" : "Swapping in Progress")
            .bold()
            .font(.custom("Avernir", size: 20))
            .foregroundColor(.charcoal1)
            .opacity(0.7)
    }
}

struct StartNextPositionButton_Previews: PreviewProvider {
    static var previews: some View {
        StartNextPositionButton()
            .environmentObject(PatientMonitorDriver())
    }
}
