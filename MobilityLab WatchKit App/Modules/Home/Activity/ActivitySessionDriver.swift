//
//  ActivitySessionDriver.swift
//  MobilityLab WatchKit App
//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import WatchKit

final class ActivitySessionDriver: ObservableObject {
    @Published var steps: Double = 0
    @Published var heartRate: Double = 0
    @Published var calories: Double = 0
    @Published var distance: Double = 0   // meters
    @Published var elapsedSeconds: Int = 0
    @Published var wearLocation: WearLocation = .unknown

    private var sessionStartDate = Date()

    @Injected(\.workoutSession) private var workoutSession
    @Injected(\.watchConnectivityService) private var connectivityService
    @Injected(\.locationService) private var locationService

    private var timer: Timer?
    private var dataTimer: Timer?
    private var sensorTimer: Timer?
    private let deviceMotionManager: DeviceMotionManagerProtocol = DeviceMotionManager.shared
    private let motionDetector = MotionActivityDetector(sampleRate: 25.0)

    // MARK: - Formatted Values

    var formattedDuration: String {
        let hours = elapsedSeconds / 3600
        let mins = (elapsedSeconds % 3600) / 60
        let secs = elapsedSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }

    var formattedSteps: String {
        if steps >= 1000 {
            return String(format: "%.1fk", steps / 1000.0)
        }
        return String(format: "%.0f", steps)
    }

    var formattedHeartRate: String {
        heartRate > 0 ? String(format: "%.0f", heartRate) : "--"
    }

    var formattedCalories: String {
        String(format: "%.0f", calories)
    }

    var formattedDistance: String {
        String(format: "%.2f", distance / 1000.0)
    }

    // MARK: - Session Lifecycle

    func startSession() {
        sessionStartDate = Date()

        // Reset sensor-based detector
        motionDetector.reset()

        // Increase sample rate for step detection (default 2Hz is too slow)
        deviceMotionManager.sampleRate = 25.0

        workoutSession.startWorkout()
        locationService.startLocationUpdate()
        deviceMotionManager.initaliseDatasources()
        WKInterfaceDevice.current().play(.start)

        // Duration timer (1s)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }

        // Sensor polling timer (25Hz) — directly feeds accelerometer data to the motion detector
        sensorTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 25.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let dataPoint = self.deviceMotionManager.getDataPoint()
            self.motionDetector.processMotionData(dataPoint)
        }

        // Data sync timer — merge HealthKit + sensor data and send to iPhone every 2 seconds
        dataTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.pollWorkoutData()
        }
    }

    func stopSession() {
        timer?.invalidate()
        dataTimer?.invalidate()
        sensorTimer?.invalidate()
        workoutSession.stopWorkout()
        locationService.stopLocationUpdate()
        deviceMotionManager.deinitDatasources()

        // Final merge of sensor + HealthKit data
        pollWorkoutData()

        // Send completed activity data to iPhone
        var completedData = buildMergedHealthData()
        completedData["activityCompleted"] = true
        completedData["startTime"] = sessionStartDate.timeIntervalSince1970
        completedData["endTime"] = Date().timeIntervalSince1970
        completedData["duration"] = elapsedSeconds
        completedData["wearLocation"] = motionDetector.detectedLocation.rawValue
        connectivityService.sendHealthData(completedData)
    }

    // MARK: - Data Polling

    /// Merges HealthKit data (accurate on wrist) with sensor-derived data (works anywhere).
    /// Takes the maximum of each metric so the best source wins automatically.
    private func pollWorkoutData() {
        let hkSteps = workoutSession.stepCount
        let sensorSteps = Double(motionDetector.stepCount)

        let hkDistance = workoutSession.distance
        let sensorDistance = motionDetector.estimatedDistance

        let hkCalories = workoutSession.activeCalories
        let sensorCalories = motionDetector.estimatedCalories

        // Best-of-both: HealthKit is accurate on wrist; sensor works on chest/ankle/foot
        steps = max(hkSteps, sensorSteps)
        distance = max(hkDistance, sensorDistance)
        calories = max(hkCalories, sensorCalories)

        // Heart rate only comes from HealthKit (requires skin contact)
        heartRate = workoutSession.heartRate

        // Update detected wear location
        wearLocation = motionDetector.detectedLocation

        connectivityService.sendHealthData(buildMergedHealthData())
    }

    /// Builds the data dictionary with merged sensor + HealthKit values.
    private func buildMergedHealthData() -> [String: Any] {
        [
            "stepCount": steps,
            "heartRate": heartRate,
            "heartRateAvg": workoutSession.heartRateAvg,
            "heartRateMax": workoutSession.heartRateMax,
            "distance": distance,
            "activeCalories": calories,
            "wearLocation": motionDetector.detectedLocation.rawValue,
            "isMoving": motionDetector.isMoving,
            "timestamp": Date().timeIntervalSince1970,
        ]
    }
}
