//
//  MotionActivityDetector.swift
//  MobilityLab WatchKit App
//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import CoreMotion
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
/// Uses CMPedometer as the primary step source (hardware-accelerated, accurate on wrist),
/// with accelerometer-based step detection as fallback for non-wrist placements.
/// Wear location is classified from gravity vector and acceleration patterns.
final class MotionActivityDetector {

    // MARK: - Public Metrics

    private(set) var pedometerSteps: Int = 0
    private(set) var pedometerDistance: Double = 0   // meters
    private(set) var sensorSteps: Int = 0
    private(set) var movementIntensity: Double = 0
    private(set) var estimatedCalories: Double = 0   // kcal
    private(set) var detectedLocation: WearLocation = .unknown
    private(set) var isMoving: Bool = false

    /// User-specified placement (set before session starts). Overrides auto-detection.
    var userPlacement: WearLocation = .wrist

    /// Effective placement: user-specified unless auto-detection has very high confidence
    var effectivePlacement: WearLocation {
        userPlacement
    }

    /// Best available step count (pedometer preferred, sensor fallback)
    var stepCount: Int {
        max(pedometerSteps, sensorSteps)
    }

    /// Best available distance
    var estimatedDistance: Double {
        if pedometerDistance > 0 {
            return pedometerDistance
        }
        // Fallback: stride-based estimate adjusted for placement
        let stride: Double
        switch effectivePlacement {
        case .ankle: stride = movementIntensity > 0.4 ? 1.1 : 0.65
        case .chest: stride = movementIntensity > 0.4 ? 0.95 : 0.60
        case .wrist: stride = movementIntensity > 0.4 ? 0.78 : 0.55
        case .unknown: stride = movementIntensity > 0.4 ? 0.75 : 0.50
        }
        return Double(sensorSteps) * stride
    }

    // MARK: - Configuration

    private let bodyWeightKg: Double

    // MARK: - CMPedometer

    private let pedometer = CMPedometer()
    private var pedometerStartDate: Date?

    // MARK: - Step Detection State (accelerometer-based fallback)

    private var magnitudeWindow: [Double] = []
    private let windowSize = 38                 // ~1.5s at 25Hz
    private var lastStepRealTime: TimeInterval = 0
    private var wasAboveMid: Bool = false

    // MARK: - Wear Location State

    private var gravityHistory: [(x: Double, y: Double, z: Double)] = []
    private var accelAmplitudes: [Double] = []
    private let locationSampleSize = 75         // ~3s at 25Hz

    // MARK: - Calorie / Movement State

    private var activeSeconds: Double = 0
    private let movementThreshold: Double = 0.02
    private var recentMagnitudes: [Double] = []
    private let movementWindowSize = 15
    private var lastProcessTime: TimeInterval = 0

    // MARK: - Init

    init(sampleRate: Double = 25.0, bodyWeightKg: Double = 70.0) {
        self.bodyWeightKg = bodyWeightKg
    }

    /// Reset all accumulated metrics for a new session.
    func reset() {
        pedometerSteps = 0
        pedometerDistance = 0
        sensorSteps = 0
        movementIntensity = 0
        estimatedCalories = 0
        detectedLocation = .unknown
        isMoving = false
        magnitudeWindow.removeAll()
        lastStepRealTime = 0
        wasAboveMid = false
        gravityHistory.removeAll()
        accelAmplitudes.removeAll()
        activeSeconds = 0
        recentMagnitudes.removeAll()
        lastProcessTime = 0
        pedometerStartDate = nil
    }

    // MARK: - CMPedometer (Primary Step Source)

    /// Start the pedometer for hardware-accelerated step counting.
    func startPedometer() {
        guard CMPedometer.isStepCountingAvailable() else {
            logger.info("CMPedometer step counting not available")
            return
        }

        let start = Date()
        pedometerStartDate = start

        pedometer.startUpdates(from: start) { [weak self] data, error in
            guard let self, let data else {
                if let error { logger.error("Pedometer error: \(error.localizedDescription)") }
                return
            }
            self.pedometerSteps = data.numberOfSteps.intValue
            self.pedometerDistance = data.distance?.doubleValue ?? 0
        }
    }

    /// Stop the pedometer.
    func stopPedometer() {
        pedometer.stopUpdates()
    }

    // MARK: - Core Processing (Accelerometer Data)

    func processMotionData(_ dataPoint: DataPoint) {
        // Use real wall-clock time for accurate cadence validation
        let now = ProcessInfo.processInfo.systemUptime

        // 1. Acceleration magnitude (orientation-agnostic, gravity-free)
        let xA = dataPoint.xAccel
        let yA = dataPoint.yAccel
        let zA = dataPoint.zAccel
        let magnitude = sqrt(xA * xA + yA * yA + zA * zA)

        // 2. Update sliding window for min/max peak detection
        magnitudeWindow.append(magnitude)
        if magnitudeWindow.count > windowSize {
            magnitudeWindow.removeFirst()
        }

        // 3. Step detection using min-max midpoint crossing (fallback for non-wrist)
        if magnitudeWindow.count >= 10 {
            detectStep(magnitude: magnitude, realTime: now)
        }

        // 4. Movement detection
        recentMagnitudes.append(magnitude)
        if recentMagnitudes.count > movementWindowSize {
            recentMagnitudes.removeFirst()
        }
        let avgMagnitude = recentMagnitudes.reduce(0, +) / Double(recentMagnitudes.count)
        isMoving = avgMagnitude > movementThreshold

        // 5. Movement intensity (0-1, calibrated for real walking ~0.1-0.5g)
        movementIntensity = min(1.0, avgMagnitude / 0.5)

        // 6. Accumulate active time using real elapsed time
        if isMoving && lastProcessTime > 0 {
            activeSeconds += now - lastProcessTime
        }
        lastProcessTime = now

        // 7. Update calorie estimate
        updateCalories()

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

    private func detectStep(magnitude: Double, realTime: TimeInterval) {
        let windowMin = magnitudeWindow.min() ?? 0
        let windowMax = magnitudeWindow.max() ?? 0
        let range = windowMax - windowMin

        // Need sufficient signal variation (filters out noise at rest)
        guard range > 0.012 else {
            wasAboveMid = false
            return
        }

        let midpoint = windowMin + range * 0.4

        let isAboveMid = magnitude > midpoint

        // Detect upward crossing → one step
        if isAboveMid && !wasAboveMid {
            let interval = realTime - lastStepRealTime

            // Walking cadence: 0.25s–2.0s per step (real wall-clock time)
            if lastStepRealTime == 0 || (interval > 0.25 && interval < 2.0) {
                sensorSteps += 1
                lastStepRealTime = realTime
            }
        }

        wasAboveMid = isAboveMid
    }

    // MARK: - Calorie Estimation

    private func updateCalories() {
        let met: Double
        if movementIntensity < 0.1 {
            met = 1.3
        } else if movementIntensity < 0.3 {
            met = 3.0
        } else if movementIntensity < 0.55 {
            met = 4.5
        } else if movementIntensity < 0.75 {
            met = 6.0
        } else {
            met = 8.5
        }
        estimatedCalories = met * bodyWeightKg * (activeSeconds / 3600.0)
    }

    // MARK: - Wear Location Classification

    /// Classifies device placement from gravity vector stability and acceleration patterns.
    ///
    /// - **Ankle/Foot**: High accel variance + large gravity swings (leg rotation)
    /// - **Wrist**: Moderate accel + moderate gravity swing (arm swing)
    /// - **Chest**: Very low accel variance + very stable gravity (torso is stable during walking)
    private func classifyWearLocation() {
        guard gravityHistory.count >= 2 else { return }

        let meanAmp = accelAmplitudes.reduce(0, +) / Double(accelAmplitudes.count)
        var ampVar: Double = 0
        for a in accelAmplitudes {
            let d = a - meanAmp
            ampVar += d * d
        }
        ampVar /= Double(accelAmplitudes.count)

        var gravVar: Double = 0
        for i in 1..<gravityHistory.count {
            let dx = gravityHistory[i].x - gravityHistory[i - 1].x
            let dy = gravityHistory[i].y - gravityHistory[i - 1].y
            let dz = gravityHistory[i].z - gravityHistory[i - 1].z
            gravVar += dx * dx + dy * dy + dz * dz
        }
        gravVar /= Double(gravityHistory.count - 1)

        // Ankle: very high motion + large orientation changes
        if ampVar > 0.3 && gravVar > 0.06 {
            detectedLocation = .ankle
        }
        // Chest: torso barely moves during walking — very stable
        else if ampVar < 0.003 && gravVar < 0.001 {
            detectedLocation = .chest
        }
        // Default: wrist (arm swing produces moderate motion + gravity change)
        else {
            detectedLocation = .wrist
        }
    }
}
