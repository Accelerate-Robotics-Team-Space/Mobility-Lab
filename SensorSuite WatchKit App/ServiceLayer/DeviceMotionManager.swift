//
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//
//  Adapted from Alex Gubbay under MIT license
//  https://github.com/agbb/DataFil/blob/master/DataFil/library/FilterModel/DataSourceManager.swift
//
//  Created by Alex Gubbay on 08/12/2016.
//  Copyright © 2016 Alex Gubbay. All rights reserved.
//

import CoreMotion
import FactoryKit
import Foundation

protocol DeviceMotionManagerProtocol: AnyObject {
    func initaliseDatasources()
    func processDeviceMotion(_ deviceMotion: CMDeviceMotion)
    func getDataPoint() -> DataPoint
    func getDataPoint(_ deviceMotion: CMDeviceMotion?) -> DataPoint
    func deinitDatasources()
    var sampleRate: Double { get set }
}

/// Manages sensor data collection.
///
/// - Important
///   Ensure that there is only a single instance of `DataSourceManager` in the App.
final class DeviceMotionManager: DeviceMotionManagerProtocol {
    static let shared: DeviceMotionManagerProtocol = DeviceMotionManager()
    static let newDataNote = Notification.Name("data.source.manager_new.raw.data")

    private var motionManager: CMMotionManager = {
        let manager = CMMotionManager()
        manager.deviceMotionUpdateInterval = 1.0
        manager.startDeviceMotionUpdates()
        return manager
    }()
    private lazy var queue: OperationQueue = .init()
    private var count: Int = 0
    var sampleRate: Double = 2.0 {
        didSet {
            applySampleRate()
        }
    }

    @Injected(\.notificationCenter) private var notificationCenter

    // MARK: - Init
    private init() {
        notificationCenter.addObserver(
            self,
            selector: #selector(newDatasourceSettings),
            name: Notification.Name("newDatasourceSettings"),
            object: nil
        )
    }

    // MARK: - Util Methods

    /// Starts the data sources up and when ready begins broadcasting data objects via the `newRawData` notification.
    func initaliseDatasources() {
        guard motionManager.isDeviceMotionAvailable else {
            logger.warn("No sensors available")
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / sampleRate
        motionManager.startDeviceMotionUpdates(to: queue) { deviceMotion, error in
            guard let motion = deviceMotion, error == nil else {
                logger.error("Motion Manager encountered error: \(error?.localizedDescription ?? "?")")
                return
            }

            self.processDeviceMotion(motion)
        }
    }

    func processDeviceMotion(_ deviceMotion: CMDeviceMotion) {
        count += 1

        let accel = getDataPoint(deviceMotion)

        notificationCenter.post(
            name: DeviceMotionManager.newDataNote,
            object: nil,
            userInfo: ["data": accel]
        )
    }

    func getDataPoint() -> DataPoint {
        getDataPoint(nil)
    }

    // nEdd motionmanger to receive update,
    func getDataPoint(_ deviceMotion: CMDeviceMotion?) -> DataPoint {
        let accel = DataPoint()
        accel.id = Int64(count)

        guard let deviceMotion = deviceMotion ?? motionManager.deviceMotion else {
            return accel
        }

        // Store Acceleration Data
        accel.xAccel = deviceMotion.userAcceleration.x
        accel.yAccel = deviceMotion.userAcceleration.y
        accel.zAccel = deviceMotion.userAcceleration.z
        accel.xGravity = deviceMotion.gravity.x
        accel.yGravity = deviceMotion.gravity.y
        accel.zGravity = deviceMotion.gravity.z
        accel.xRotationRate = deviceMotion.rotationRate.x
        accel.yRotationRate = deviceMotion.rotationRate.y
        accel.zRotationRate = deviceMotion.rotationRate.z
        accel.pitchAttitude = deviceMotion.attitude.pitch
        accel.rollAttitude = deviceMotion.attitude.roll
        accel.yawAttitude = deviceMotion.attitude.yaw

        return accel
    }

    /// Shuts down data sources. Use to conserve power.
    func deinitDatasources() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.stopDeviceMotionUpdates()
        }
    }
}

// MARK: - Private Extension
private extension DeviceMotionManager {
    /// Nominated by the observer to be called when notified of new settings for data sources. Called when a
    /// notification with the format ["sampleRate":Double] and the name "newDataSourceSettings" is posted
    /// to update the sample rate of the sensors.
    @objc
    func newDatasourceSettings(notification: NSNotification) {
        guard let data = notification.userInfo as? [String: Double],
              let newSampleRate = data["sampleRate"] else {
            logger.warn("Could not cast userInfo from notification")
            return
        }

        sampleRate = newSampleRate
        applySampleRate()
    }

    private func applySampleRate() {
        if motionManager.isAccelerometerAvailable {
            if motionManager.isAccelerometerActive != false {
                logger.debug("notified \(sampleRate)")
                motionManager.accelerometerUpdateInterval = 1.0 / sampleRate
            } else {
                logger.debug("accelerometer not active")
            }
        }
        motionManager.deviceMotionUpdateInterval = 1.0 / sampleRate
    }
}
