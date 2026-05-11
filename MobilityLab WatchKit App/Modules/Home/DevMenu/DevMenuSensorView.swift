//
//  DevMenuSensorView.swift
//  MobilityLab WatchKit Extension
//
//  Created by Josh Franco on 8/11/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DevMenuSensorView: View {
    @EnvironmentObject var sensor: DevSensorDriver
    
    private let sizeMultiplier: CGFloat = 0.91
    @State private var progress: Float = 0
    
    var body: some View {
        GeometryReader { geo in
            Form {
                ZStack {
//                    CompletionCircleView(progress: self.sensor.isSensing ? 1: 0,
//                                         primary: .blue,
//                                         secondary: .red,
//                                         showPercentage: false)
//                        .frame(width: (geo.size.width * self.sizeMultiplier) - 16,
//                               height: (geo.size.width * self.sizeMultiplier) - 24)
                    
                    Button(action: {
                        withAnimation {
                            self.sensor.isSensing.toggle()
                        }
                    }) {
                        Text(self.sensor.isSensing ? "Stop" : "Start")
                            .font(.title)
                            .bold()
                            .minimumScaleFactor(0.5)
                            .frame(width: geo.size.width * self.sizeMultiplier,
                                   height: geo.size.width * self.sizeMultiplier,
                                   alignment: .center)
                    }
                }
                .padding(.vertical, 4)
                
                HStack {
                    Image(systemName: self.sensor.isBleConnected ? "link.circle.fill" : "link.circle")

                    Divider()
                    
                    Image(systemName: "heart.fill")
                    
                    Spacer()
                    
                    Image(systemName: "tray")
                    
                    Text("\(self.sensor.packetsInQueue)")
                }
                
                Picker("Buffer Size", selection: self.$sensor.bufferSizeIndex) {
                    ForEach(self.sensor.bufferSizes, id: \.self) { item in
                        Text("\(item) packets")
                    }
                }
                
                Text("Sensor ID: 001")
                
                Text("Connected to \(self.sensor.peripheralName ?? "n/a")")
            }
        }
    }
}

struct WatchSensorView_Previews: PreviewProvider {
    static var previews: some View {
        DevMenuSensorView()
            .environmentObject(DevSensorDriver())
    }
}
