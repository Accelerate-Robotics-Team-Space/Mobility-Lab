//
//  ComplianceBar.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 4/5/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ComplianceBar: View {
    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    
    @State private var compliancePercentage: Int = 100
    @State private var complianceBarColor: Color = .green1
    @State private var isPaused: Bool = true

    var body: some View {
        VStack {
            VStack(spacing: 5) {
                HStack {
                    currentComplianceText
                    Spacer()
                    percentBar
                }
                .padding(.horizontal)
                progressBar
            }
        }
    }

    @ViewBuilder
    private var currentComplianceText: some View {
        Text(R.string.localizable.currentTurnCompliance())
            .textCase(.uppercase)
            .font(.custom("Avenir-Roman", size: 12))
            .foregroundColor(.charcoal3)
    }

    @ViewBuilder
    private var percentBar: some View {
        Text("\(compliancePercentage)%")
            .font(.custom("Avenir-Roman", size: 12))
            .foregroundColor(self.isPaused ? .charcoal3 : complianceBarColor)
            .onChange(of: patientMonitorDriver.currentState) { newValue in
                self.isPaused = newValue == .onPause
            }
            .onReceive(patientMonitorDriver.$compliancePercentage) { compliancePercentage in
                handleCompliancePercentage(compliancePercentage)
            }
    }

    @ViewBuilder
    private var progressBar: some View {
        ProgressBar(
            value: patientMonitorDriver.compliancePercentage >= 0
            ? patientMonitorDriver.compliancePercentage
            : 0,
            isPaused: isPaused
        )
        .frame(maxHeight: 8)
    }

    private func handleCompliancePercentage(_ percentage: Double) {
        withAnimation(.linear(duration: 0.5)) {
            if percentage >= 0 {
                self.compliancePercentage = Int((percentage * 100).rounded())
            } else {
                self.compliancePercentage = 0
            }
            if percentage < 0.5 {
                self.complianceBarColor = .red1
            } else if percentage < 0.79 {
                self.complianceBarColor = .yellow1
            } else {
                self.complianceBarColor = .green1
            }
        }
    }
}

struct ComplianceBar_Previews: PreviewProvider {
    static var previews: some View {
        ComplianceBar()
            .environmentObject(PatientMonitorDriver())
    }
}
