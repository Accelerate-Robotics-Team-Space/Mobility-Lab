//
//  MotionActivityDetector.swift
//  MobilityLab WatchKit App
//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

// MARK: - Wear Location

enum WearLocation: String {
    case wrist
    case chest
    case ankle
    case unknown

    var displayName: String {
        switch self {
        case .wrist: return "Wrist"
        case .chest: return "Chest"
        case .ankle: return "Ankle/Foot"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - Motion Activity Detector

/// Detects steps, movement, and wear location from raw accelerometer data.
/// Works regardless of where the device is worn (wrist, chest, ankle/foot).
///
/// Uses acceleration magnitude peak detection which is orientation-agnostic,
/// combined with gravity vector analysis for wear location classification.
///
/// Data is fed directly via `processMotionData(_:)` from the driver's polling timer,
/// avoiding notification center mismatch issues.
final class MotionActivityDetector {

    // MARK: - Public Metrics

    private(set) var stepCount: Int = 0
    private(set) var movementIntensity: Double = 0
    private(set) var estimatedDistance: Double = 0   // meters
    private(set) var estimatedCalories: Double = 0   // kcal
    private(set) var detectedLocation: WearLocation = .unknown
    private(set) var isMoving: Bool = false

    // MARK: - Configuration

    private let sampleRate: Double
    private let bodyWeightKg: Double

    // MARK: - Step Detection State (min-max peak detection)

    private var magnitudeWindow: [Double] = []
    private let windowSize: Int              // sliding window for min/max
    private var lastStepTime: TimeInterval = 0
    private var wasAboveMid: Bool = false
    private var sampleCounter: Int = 0

    // MARK: - Wear Location State

    private var gravityHistory: [(x: Double, y: Double, z: Double)] = []
    private var accelAmplitudes: [Double] = []
    private let locationSampleSize: Int

    // MARK: - Calorie / Movement State

    private var activeSeconds: Double = 0
    private let movementThreshold: Double = 0.02
    private var recentMagnitudes: [Double] = []
    private let movementWindowSize = 15

    // MARK: - Init

    /// - Parameters:
    ///   - sampleRate: Expected sensor sample rate in Hz (should match DeviceMotionManager).
    ///   - bodyWeightKg: User's body weight for calorie estimation. Defaults to 70 kg.
    init(sampleRate: Double = 25.0, bodyWeightKg: Double = 70.0) {
        self.sampleRate = sampleRate
        self.bodyWeightKg = bodyWeightKg
        self.windowSize = Int(sampleRate * 1.5)        // 1.5 seconds for min/max window
        self.locationSampleSize = Int(sampleRate * 3)  // 3 seconds for classification
    }

    /// Reset all accumulated metrics for a new session.
    func reset() {
        stepCount = 0
        movementIntensity = 0
        estimatedDistance = 0
        estimatedCalories = 0
        detectedLocation = .unknown
        isMoving = false
        magnitudeWindow.removeAll()
        lastStepTime = 0
        wasAboveMid = false
        sampleCounter = 0
        gravityHistory.removeAll()
        accelAmplitudes.removeAll()
        activeSeconds = 0
        recentMagnitudes.removeAll()
    }

    // MARK: - Core Processing

    func processMotionData(_ dataPoint: DataPoint) {
        sampleCounter += 1
        let timestamp = Double(sampleCounter) / sampleRate

        // 1. Acceleration magnitude (orientation-agnostic, gravity-free)
        let magnitude = sqrt(
            dataPoint.xAccel * dataPoint.xAccel +
            dataPoint.yAccel * dataPoint.yAccel +
            dataPoint.zAccel * dataPoint.zAccel
        )

        // 2. Update sliding window for min/max peak detection
        magnitudeWindow.append(magnitude)
        if magnitudeWindow.count > windowSize {
            magnitudeWindow.removeFirst()
        }

        // 3. Step detection using min-max midpoint crossing
        if magnitudeWindow.count >= 10 {
            detectStep(magnitude: magnitude, timestamp: timestamp)
        }

        // 4. Movement detection (short window average)
        recentMagnitudes.append(magnitude)
        if recentMagnitudes.count > movementWindowSize {
            recentMagnitudes.removeFirst()
        }
        let avgMagnitude = recentMagnitudes.reduce(0, +) / Double(recentMagnitudes.count)
        isMoving = avgMagnitude > movementThreshold

        // 5. Movement intensity (0-1 scale, calibrated for real walking ~0.1-0.5g)
        movementIntensity = min(1.0, avgMagnitude / 0.6)

        // 6. Accumulate active time
        if isMoving {
            activeSeconds += 1.0 / sampleRate
        }

        // 7. Update derived metrics
        updateCalories()
        updateDistance()

        // 8. Wear location classification
        gravityHistory.append((x: dataPoint.xGravity, y: dataPoint.yGravity, z: dataPoint.zGravity))
        accelAmplitudes.append(magnitude)
        if gravityHistory.count > locationSampleSize {
            gravityHistory.removeFirst()
            accelAmplitudes.removeFirst()
        }
        if gravityHistory.count >= locationSampleSize {
            classifyWearLocation()
        }
    }

    // MARK: - Step Detection (Min-Max Midpoint Crossing)

    /// Detects steps by tracking when the acceleration magnitude crosses the midpoint
    /// between the recent min and max values (going upward). This adapts automatically
    /// to any signal amplitude, making it work at any body placement.
    private func detectStep(magnitude: Double, timestamp: TimeInterval) {
        let windowMin = magnitudeWindow.min() ?? 0
        let windowMax = magnitudeWindow.max() ?? 0
        let range = windowMax - windowMin

        // Need sufficient signal variation to detect steps (filters out noise at rest)
        guard range > 0.015 else {
            wasAboveMid = false
            return
        }

        let midpoint = windowMin + range * 0.4  // slightly below center to catch more peaks

        let isAboveMid = magnitude > midpoint

        // Detect upward crossing of midpoint → one step
        if isAboveMid && !wasAboveMid {
            let interval = timestamp - lastStepTime

            // Validate cadence: 0.2s–2.0s per step (very wide range for all gaits)
            if lastStepTime == 0 || (interval > 0.2 && interval < 2.0) {
                stepCount += 1
                lastStepTime = timestamp
            }
        }

        wasAboveMid = isAboveMid
    }

    // MARK: - Calorie Estimation

    /// MET-based calorie estimation from movement intensity.
    private func updateCalories() {
        let met: Double
        if movementIntensity < 0.1 {
            met = 1.3  // sedentary / very light
        } else if movementIntensity < 0.3 {
            met = 3.0  // light walk
        } else if movementIntensity < 0.55 {
            met = 4.5  // moderate walk
        } else if movementIntensity < 0.75 {
            met = 6.0  // brisk walk
        } else {
            met = 8.5  // running
        }
        // kcal = MET x bodyWeight(kg) x time(hours)
        estimatedCalories = met * bodyWeightKg * (activeSeconds / 3600.0)
    }

    // MARK: - Distance Estimation

    /// Stride-length based distance from step count, adjusted for wear location and intensity.
    private func updateDistance() {
        let strideLength: Double
        switch detectedLocation {
        case .ankle:
            strideLength = movementIntensity > 0.4 ? 1.1 : 0.65
        case .chest:
            strideLength = movementIntensity > 0.4 ? 0.95 : 0.60
        case .wrist:
            strideLength = movementIntensity > 0.4 ? 0.78 : 0.55
        case .unknown:
            strideLength = movementIntensity > 0.4 ? 0.75 : 0.50
        }
        estimatedDistance = Double(stepCount) * strideLength
    }

    // MARK: - Wear Location Classification

    /// Classifies device placement using gravity vector stability and acceleration amplitude patterns.
    ///
    /// - **Ankle/Foot**: High acceleration variance, large gravity vector swings during walking
    /// - **Chest**: Low acceleration variance, very stable gravity vector
    /// - **Wrist**: Moderate acceleration, moderate gravity swing from arm swing
    private func classifyWearLocation() {
        guard gravityHistory.count >= 2 else { return }

        let meanAmplitude = accelAmplitudes.reduce(0, +) / Double(accelAmplitudes.count)
        let amplitudeVariance = accelAmplitudes.map { ($0 - meanAmplitude) * ($0 - meanAmplitude) }
            .reduce(0, +) / Double(accelAmplitudes.count)

        var gravityVariance: Double = 0
        for i in 1..<gravityHistory.count {
            let dx = gravityHistory[i].x - gravityHistory[i - 1].x
            let dy = gravityHistory[i].y - gravityHistory[i - 1].y
            let dz = gravityHistory[i].z - gravityHistory[i - 1].z
            gravityVariance += dx * dx + dy * dy + dz * dz
        }
        gravityVariance /= Double(gravityHistory.count - 1)

        if amplitudeVariance > 0.3 && gravityVariance > 0.06 {
            detectedLocation = .ankle
        } else if amplitudeVariance < 0.08 && gravityVariance < 0.01 {
            detectedLocation = .chest
        } else {
            detectedLocation = .wrist
        }
    }
}
