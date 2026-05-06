//
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//
//  Adapted from Alex Gubbay under MIT license
//  https://github.com/agbb/DataFil/blob/master/DataFil/library/FilterModel/accelPoint.swift
//
//  Created by Alex Gubbay on 08/12/2016.
//  Copyright © 2016 Alex Gubbay. All rights reserved.
//

import Foundation

/// Data object representing a set of sensor readings from a single point in time.
class DataPoint: Identifiable {
    static var supportsSecureCoding: Bool = true
    
    var id: Int64 = 0
    
    var xAccel = 0.0
    var yAccel = 0.0
    var zAccel = 0.0
    var xGravity = 0.0
    var yGravity = 0.0
    var zGravity = 0.0
    var xRotationRate = 0.0
    var yRotationRate = 0.0
    var zRotationRate = 0.0
    var rollAttitude = 0.0
    var pitchAttitude = 0.0
    var yawAttitude = 0.0
    
    // MARK: - Initializers
    required init?(serialize data: Data) {
        guard
            let idData = data.to(type: Int64.self, from: 0),
            let xAccelData = data.to(type: Double.self, from: 8),
            let yAccelData = data.to(type: Double.self, from: 16),
            let zAccelData = data.to(type: Double.self, from: 24),
            let xGravityData = data.to(type: Double.self, from: 32),
            let yGravityData = data.to(type: Double.self, from: 40),
            let zGravityData = data.to(type: Double.self, from: 48),
            let xRotationRateData = data.to(type: Double.self, from: 56),
            let yRotationRateData = data.to(type: Double.self, from: 64),
            let zRotationRateData = data.to(type: Double.self, from: 72),
            let rollAttitudeData = data.to(type: Double.self, from: 80),
            let pitchAttitudeData = data.to(type: Double.self, from: 88),
            let yawAttitudeData = data.to(type: Double.self, from: 96) else { return nil }
        
        self.id = Int64(bigEndian: idData)
        self.xAccel = Double(bitPattern: xAccelData.bitPattern.bigEndian)
        self.yAccel = Double(bitPattern: yAccelData.bitPattern.bigEndian)
        self.zAccel = Double(bitPattern: zAccelData.bitPattern.bigEndian)
        self.xGravity = Double(bitPattern: xGravityData.bitPattern.bigEndian)
        self.yGravity = Double(bitPattern: yGravityData.bitPattern.bigEndian)
        self.zGravity = Double(bitPattern: zGravityData.bitPattern.bigEndian)
        self.xRotationRate = Double(bitPattern: xRotationRateData.bitPattern.bigEndian)
        self.yRotationRate = Double(bitPattern: yRotationRateData.bitPattern.bigEndian)
        self.zRotationRate = Double(bitPattern: zRotationRateData.bitPattern.bigEndian)
        self.rollAttitude = Double(bitPattern: rollAttitudeData.bitPattern.bigEndian)
        self.pitchAttitude = Double(bitPattern: pitchAttitudeData.bitPattern.bigEndian)
        self.yawAttitude = Double(bitPattern: yawAttitudeData.bitPattern.bigEndian)
    }
    
    init() {
        self.id = Date().millisecondsSince1970
    }
    
    /// Create a fully initialized DataPoint
    /// - Parameters:
    ///   - xAccel: Acceleration on the X axis
    ///   - yAccel: Acceleration on the Y axis
    ///   - zAccel: Acceleration on the Z axis
    ///   - xGravity: Gravity on the X axis
    ///   - yGravity: Gravity on the Y axis
    ///   - zGravity: Gravity on the Z axis
    ///   - xRotationRate: Rotation rate on the X axis
    ///   - yRotationRate: Rotation rate on the Y axis
    ///   - zRotationRate: Rotation rate on the Z axis
    ///   - rollAttitude: Attitude of the roll
    ///   - pitchAttitude: Attitude of the pitch
    ///   - yawAttitude: Attitude of the yaw
    init(id: Int64,
         xAccel: Double, yAccel: Double, zAccel: Double,
         xGravity: Double, yGravity: Double, zGravity: Double,
         xRotationRate: Double, yRotationRate: Double, zRotationRate: Double,
         rollAttitude: Double, pitchAttitude: Double, yawAttitude: Double) {
        self.id = id
        
        self.xAccel = xAccel
        self.yAccel = yAccel
        self.zAccel = zAccel
        self.xGravity = xGravity
        self.yGravity = yGravity
        self.zGravity = zGravity
        self.xRotationRate = xRotationRate
        self.yRotationRate = yRotationRate
        self.zRotationRate = zRotationRate
        self.rollAttitude = rollAttitude
        self.pitchAttitude = pitchAttitude
        self.yawAttitude = yawAttitude
    }
}

// MARK: - BleSerializeable
extension DataPoint: Serializable {
     func toData() -> Data {
         var buffer = Data(capacity: 104)
         
         buffer.append(Data(from: self.id.bigEndian))
         buffer.append(Data(from: self.xAccel.bitPattern.bigEndian))
         buffer.append(Data(from: self.yAccel.bitPattern.bigEndian))
         buffer.append(Data(from: self.zAccel.bitPattern.bigEndian))
         buffer.append(Data(from: self.xGravity.bitPattern.bigEndian))
         buffer.append(Data(from: self.yGravity.bitPattern.bigEndian))
         buffer.append(Data(from: self.zGravity.bitPattern.bigEndian))
         buffer.append(Data(from: self.xRotationRate.bitPattern.bigEndian))
         buffer.append(Data(from: self.yRotationRate.bitPattern.bigEndian))
         buffer.append(Data(from: self.zRotationRate.bitPattern.bigEndian))
         buffer.append(Data(from: self.rollAttitude.bitPattern.bigEndian))
         buffer.append(Data(from: self.pitchAttitude.bitPattern.bigEndian))
         buffer.append(Data(from: self.yawAttitude.bitPattern.bigEndian))
         
         return buffer
     }
}
