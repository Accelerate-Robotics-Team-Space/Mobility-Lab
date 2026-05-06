//
//  TrainView.swift
//  SensorSuite WatchKit Extension
//
//  Created by Anton Vishnyak on 4/11/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct TrainView: View {
    let accel = DeviceMotionManager.shared
    @EnvironmentObject var localSensorDataBuffer: LocalSensorDataBuffer

    var body: some View {
        VStack {
            Button("Start", action: {
                self.localSensorDataBuffer.reset()
                self.accel.initaliseDatasources()
            })
            Button("Stop", action: {
                self.accel.deinitDatasources()
            })
            Text("X: \(localSensorDataBuffer.minGravityX, specifier: "%.2f") ... \(localSensorDataBuffer.maxGravityX, specifier: "%.2f")")
            Text("Y: \(localSensorDataBuffer.minGravityY, specifier: "%.2f") ... \(localSensorDataBuffer.maxGravityY, specifier: "%.2f")")
            Text("Z: \(localSensorDataBuffer.minGravityZ, specifier: "%.2f") ... \(localSensorDataBuffer.maxGravityZ, specifier: "%.2f")")
        }
    }
}

struct TrainView_Previews: PreviewProvider {
    static var previews: some View {
        TrainView()
            .environmentObject(LocalSensorDataBuffer(seedData: []))
    }
}
