//
//  PatientDetailsView.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/31/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PatientDetailsView: View {
    @ObservedObject var bmmViewModel: BMMViewModel
    
    var body: some View {
        VStack {
            ScrollView {
                PatientDetailsProfileCell(bmmViewModel: bmmViewModel,
                                          patientDetailsViewModel: bmmViewModel.patientDetailsViewModel!)
                Divider()
                PosToAvoidProfileCell(bmmViewModel: bmmViewModel,
                                      for: bmmViewModel.positionsToAvoid)
                Divider()
                PatientLocationProfileCell(bmmViewModel: bmmViewModel,
                                           unit: bmmViewModel.unit,
                                           roomBed: bmmViewModel.roomBed)
            }
        }
    }
}

struct PatientDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        PatientDetailsView(bmmViewModel: BMMViewModel(id: "1", deviceId: "ALT001", unit: "ICU", roomBed: "B123-A", bmmState: .connected,
                                                      sensorState: .connected, patientState: .active,
                                                      timeRemaining: TimeInterval(123),
                                                      turnProtocol: "",
                                                      complianceAngle: 0,
                                                      currentPos: .left,
                                                      targetPos: .left, rollAngle: 43.6,
                                                      pitchAngle: 32.5, batteryPercentage: 42,
                                                      positionsToAvoid: [], patientDetailsViewModel: .init(id: "id")))
    }
}
