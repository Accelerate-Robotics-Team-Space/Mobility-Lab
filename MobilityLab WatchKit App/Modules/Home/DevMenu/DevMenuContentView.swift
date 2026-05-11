//
//  DevMenuContentView.swift
//  MobilityLab WatchKit Extension
//
//  Created by Anton Vishnyak on 4/3/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DevMenuContentView: View {
    @EnvironmentObject var sensor: DevSensorDriver
    
    private var image = UIImage.emptyImage(with: CGSize(width: 10, height: 10))!

    fileprivate func statusBar() -> some View {
        return HStack {
            Image(systemName: self.sensor.isBleConnected ? "link.circle.fill" : "link.circle")
            Image(systemName: "heart.fill")

            Spacer()

            Image(systemName: "tray")
            Text("\(sensor.packetsInQueue)")
        }.padding()
    }

    var body: some View {
        ScrollView {
            VStack {
                statusBar()

                HStack {
                    Button("Start", action: {
                        self.sensor.isSensing = true
                    })
                        .disabled(self.sensor.isBleConnected)
                    Button("Stop", action: {
                        self.sensor.isSensing = false
                    })
                        .disabled(!self.sensor.isBleConnected)
                }

                NavigationLink(destination: Text("Descoped")) {
                    Text("Pair")
                }
                NavigationLink(destination: TrainView(), label: { Text("Train") })

                Text(self.sensor.peripheralName ?? "n/a")
            }
        }
    }
}

struct DevMenuContentView_Previews: PreviewProvider {
    static var previews: some View {
        DevMenuContentView()
            .environmentObject(LocalSensorDataBuffer(seedData: [
                DataPoint(id: 1, xAccel: 1, yAccel: 1, zAccel: 1,
                          xGravity: 2, yGravity: 2, zGravity: 2,
                          xRotationRate: 3, yRotationRate: 3, zRotationRate: 3,
                          rollAttitude: 4, pitchAttitude: 4, yawAttitude: 4),
                DataPoint(id: 2, xAccel: 1, yAccel: 1, zAccel: 1,
                          xGravity: 2, yGravity: 2, zGravity: 2,
                          xRotationRate: 3, yRotationRate: 3, zRotationRate: 3,
                          rollAttitude: 4, pitchAttitude: 4, yawAttitude: 4),
                DataPoint(id: 3, xAccel: 1, yAccel: 1, zAccel: 1,
                          xGravity: 2, yGravity: 2, zGravity: 2,
                          xRotationRate: 3, yRotationRate: 3, zRotationRate: 3,
                          rollAttitude: 4, pitchAttitude: 4, yawAttitude: 4),
                DataPoint(id: 4, xAccel: 1, yAccel: 1, zAccel: 1,
                          xGravity: 2, yGravity: 2, zGravity: 2,
                          xRotationRate: 3, yRotationRate: 3, zRotationRate: 3,
                          rollAttitude: 4, pitchAttitude: 4, yawAttitude: 4),
                DataPoint(id: 5, xAccel: 1, yAccel: 1, zAccel: 1,
                          xGravity: 2, yGravity: 2, zGravity: 2,
                          xRotationRate: 3, yRotationRate: 3, zRotationRate: 3,
                          rollAttitude: 4, pitchAttitude: 4, yawAttitude: 4),
            ]))
    }
}
