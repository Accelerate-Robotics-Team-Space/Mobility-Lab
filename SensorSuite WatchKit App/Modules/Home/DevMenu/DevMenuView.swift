//
//  DevMenuView.swift
//  SensorSuite WatchKit Extension
//
//  Created by Josh Franco on 10/28/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DevMenuView: View {
    @EnvironmentObject var sensor: DevSensorDriver
    @State var showLogs = false
    
    var body: some View {
        VStack {
            Text("Sensor 001")
                .textStyle(.header6, color: .ash)
            
            Form {
                NavigationLink(destination: DevMenuContentView()) {
                    Text("Testing Mode")
                        .textStyle(.bold, color: .ash)
                    
                    Spacer()
                    
                    Image(systemName: "gear")
                        .foregroundColor(.ash)
                }
                .frame(height: 44)
                
                NavigationLink(destination: DevMenuSensorView().environmentObject(sensor)) {
                    Text("Sensor Mode")
                        .textStyle(.bold, color: .ash)
                    
                    Spacer()
                    
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(.ash)
                }
                .frame(height: 44)
                
                Button(action: {
                    // Do Stuff
                }) {
                    HStack {
                        Text("Begin Session Initiation")
                            .textStyle(.bold, color: .ash)
                        
                        Spacer()
                        
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.ash)
                    }
                }
                .frame(height: 44)
            }
        }
    }
}

struct WatchDevLandingView_Previews: PreviewProvider {
    static var previews: some View {
        DevMenuView()
            .environmentObject(DevSensorDriver())
    }
}
