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

    @Injected(\.workoutSession) private var workoutSession
    @Injected(\.watchConnectivityService) private var connectivityService
    @Injected(\.locationService) private var locationService

    private var timer: Timer?
    private var dataTimer: Timer?
    private let deviceMotionManager: DeviceMotionManagerProtocol = DeviceMotionManager.shared

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
        workoutSession.startWorkout()
        locationService.startLocationUpdate()
        deviceMotionManager.initaliseDatasources()
        WKInterfaceDevice.current().play(.start)

        // Duration timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }

        // Data polling timer - read from workout session every 2 seconds
        dataTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.pollWorkoutData()
        }
    }

    func stopSession() {
        timer?.invalidate()
        dataTimer?.invalidate()
        workoutSession.stopWorkout()
        locationService.stopLocationUpdate()

        // Send final data
        connectivityService.sendHealthData(workoutSession.currentHealthData)
    }

    // MARK: - Data Polling

    private func pollWorkoutData() {
        steps = workoutSession.stepCount
        heartRate = workoutSession.heartRate
        distance = workoutSession.distance
        calories = workoutSession.activeCalories

        connectivityService.sendHealthData(workoutSession.currentHealthData)
    }
}
