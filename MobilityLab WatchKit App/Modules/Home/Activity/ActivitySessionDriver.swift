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
    @Published var flightsClimbed: Double = 0
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

    var formattedFlights: String {
        String(format: "%.0f", flightsClimbed)
    }

    // MARK: - Session Lifecycle

    func startSession(placement: WearLocation = .wrist) {
        sessionStartDate = Date()

        // Reset and start sensor-based detector + pedometer
        motionDetector.reset()
        motionDetector.userPlacement = placement
        motionDetector.startPedometer()

        // Set sample rate for accelerometer (used for location detection + fallback steps)
        deviceMotionManager.sampleRate = 25.0

        workoutSession.placement = placement.rawValue
        workoutSession.startWorkout()
        locationService.startLocationUpdate()
        deviceMotionManager.initaliseDatasources()
        WKInterfaceDevice.current().play(.start)

        // Duration timer (1s)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }

        // Sensor polling timer (10Hz) — feeds accelerometer data for location + fallback steps
        sensorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let dataPoint = self.deviceMotionManager.getDataPoint()
            self.motionDetector.processMotionData(dataPoint)
        }

        // Data sync timer — merge all sources and send to iPhone every 2 seconds
        dataTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.pollWorkoutData()
        }
    }

    func stopSession() {
        timer?.invalidate()
        dataTimer?.invalidate()
        sensorTimer?.invalidate()
        motionDetector.stopPedometer()
        workoutSession.stopWorkout()
        locationService.stopLocationUpdate()
        deviceMotionManager.deinitDatasources()

        // Final data merge
        pollWorkoutData()

        // Send completed activity data to iPhone
        var completedData = buildMergedHealthData()
        completedData["activityCompleted"] = true
        completedData["startTime"] = sessionStartDate.timeIntervalSince1970
        completedData["endTime"] = Date().timeIntervalSince1970
        completedData["duration"] = elapsedSeconds
        completedData["flightsClimbed"] = flightsClimbed
        completedData["cadence"] = cadence
        completedData["wearLocation"] = motionDetector.detectedLocation.rawValue
        connectivityService.sendHealthData(completedData)
    }

    // MARK: - Data Polling

    /// Merges three data sources: HealthKit, CMPedometer, and accelerometer.
    /// Takes the best value from each source automatically.
    private func pollWorkoutData() {
        // Steps: best of HealthKit, pedometer, or sensor
        let hkSteps = workoutSession.stepCount
        let detectorSteps = Double(motionDetector.stepCount)
        steps = max(hkSteps, detectorSteps)

        // Distance: best of HealthKit or pedometer/sensor
        let hkDistance = workoutSession.distance
        let detectorDistance = motionDetector.estimatedDistance
        distance = max(hkDistance, detectorDistance)

        // Calories: best of HealthKit or sensor estimate
        let hkCalories = workoutSession.activeCalories
        let sensorCalories = motionDetector.estimatedCalories
        calories = max(hkCalories, sensorCalories)

        // Heart rate: HealthKit only (requires optical sensor on skin)
        heartRate = workoutSession.heartRate

        // Flights climbed: best of HealthKit or pedometer
        let hkFlights = workoutSession.flightsClimbed
        let pedometerFlights = motionDetector.floorsAscended
        flightsClimbed = max(hkFlights, pedometerFlights)

        // Wear location: user-specified placement
        wearLocation = motionDetector.effectivePlacement

        connectivityService.sendHealthData(buildMergedHealthData())
    }

    /// Builds the data dictionary with merged values from all sources.
    /// Computes the cadence (steps per minute) from current session data.
    var cadence: Double {
        guard elapsedSeconds > 0 else { return 0 }
        return (steps / Double(elapsedSeconds)) * 60.0
    }

    private func buildMergedHealthData() -> [String: Any] {
        [
            "stepCount": steps,
            "heartRate": heartRate,
            "heartRateAvg": workoutSession.heartRateAvg,
            "heartRateMax": workoutSession.heartRateMax,
            "distance": distance,
            "activeCalories": calories,
            "flightsClimbed": flightsClimbed,
            "cadence": cadence,
            "wearLocation": motionDetector.effectivePlacement.rawValue,
            "isMoving": motionDetector.isMoving,
            "timestamp": Date().timeIntervalSince1970,
        ]
    }
}
