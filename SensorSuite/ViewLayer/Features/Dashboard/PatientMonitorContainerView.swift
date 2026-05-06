//
//  PatientMonitorContainerView.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 3/3/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PatientMonitorContainerView: View {
    @EnvironmentObject var dashboardDriver: DashboardDriver
    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    @EnvironmentObject var patientLandingDriver: PatientLandingDriver
    @EnvironmentObject var audioAlertPlayer: AudioAlertPlayer
    
    var body: some View {
        if !dashboardDriver.setupFinished {
            PatientMonitorSetupView()
                .environmentObject(dashboardDriver)
        } else if dashboardDriver.setupFinished {
            PatientMonitorView()
                .environmentObject(dashboardDriver)
                .environmentObject(patientMonitorDriver)
                .environmentObject(patientLandingDriver)
                .environmentObject(audioAlertPlayer)
        }
    }
}

struct PatientMonitorContainerView_Previews: PreviewProvider {
    static var previews: some View {
        PatientMonitorContainerView()
    }
}
