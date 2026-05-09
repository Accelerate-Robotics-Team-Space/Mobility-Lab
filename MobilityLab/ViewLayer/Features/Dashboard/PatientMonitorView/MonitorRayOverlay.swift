//
//  MonitorRayOverlay.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 4/5/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct MonitorRayOverlay: View {
    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center) {
                if patientMonitorDriver.currentState == .onResume && patientMonitorDriver.isWearableConnected {
                    ZStack {
                        Rectangle()
                            .fill(
                                RadialGradient(gradient: Gradient(colors: [
                                    Color(hex: 0xF5BC5E, opacity: 0.7),
                                    Color(hex: 0xF5BC5E, opacity: 0),
                                ]),
                                               center: .top,
                                               startRadius: 0,
                                               endRadius: 400)
                            )
                            .frame(width: geo.size.width, height: 447)
                            .cornerRadius(0)
                            .ignoresSafeArea()
                        Image(R.image.monitoringRay.name)
                            .resizable()
                            .frame(width: geo.size.width, height: 447)
                            .scaledToFit()
                            .ignoresSafeArea()
                    }
                }
            }
        }
    }
}

struct MonitorRayOverlay_Previews: PreviewProvider {
    static var previews: some View {
        MonitorRayOverlay()
            .environmentObject(PatientMonitorDriver())
    }
}
