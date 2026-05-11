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

    // MARK: - Step Detection State

    private var filteredMagnitude: Double = 0
    private let filterAlpha: Double = 0.3
    private var lastPeakTime: TimeInterval = 0
    private var isPeakPhase: Bool = false
    private var dynamicThreshold: Double = 0.15
    private var magnitudeHistory: [Double] = []
    private let historySize: Int

    // MARK: - Wear Location State

    private var gravityHistory: [(x: Double, y: Double, z: Double)] = []
    private var accelAmplitudes: [Double] = []
    private let locationSampleSize: Int

    // MARK: - Calorie / Movement State

    private var activeSeconds: Double = 0
    private let movementThreshold: Double = 0.05
    private var recentMagnitudes: [Double] = []
    private let movementWindowSize = 10

    // MARK: - Notification Observation

    private var observerToken: NSObjectProtocol?

    // MARK: - Init

    /// - Parameters:
    ///   - sampleRate: Expected sensor sample rate in Hz (should match DeviceMotionManager).
    ///   - bodyWeightKg: User's body weight for calorie estimation. Defaults to 70 kg.
    init(sampleRate: Double = 25.0, bodyWeightKg: Double = 70.0) {
        self.sampleRate = sampleRate
        self.bodyWeightKg = bodyWeightKg
        self.historySize = Int(sampleRate * 2)         // 2 seconds of history
        self.locationSampleSize = Int(sampleRate * 3)  // 3 seconds for classification
    }

    deinit {
        stopListening()
    }

    // MARK: - Lifecycle

    /// Begin observing raw sensor data from DeviceMotionManager.
    func startListening() {
        observerToken = NotificationCenter.default.addObserver(
            forName: DeviceMotionManager.newDataNote,
            object: nil,
            queue: nil // process on posting queue for low latency
        ) { [weak self] notification in
            guard let self,
                  let info = notification.userInfo as? [String: DataPoint],
                  let dataPoint = info["data"] else { return }
            self.processMotionData(dataPoint)
        }
    }

    /// Stop observing sensor data.
    func stopListening() {
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
            observerToken = nil
        }
    }

    /// Reset all accumulated metrics for a new session.
    func reset() {
        stepCount = 0
        movementIntensity = 0
        estimatedDistance = 0
        estimatedCalories = 0
        detectedLocation = .unknown
        isMoving = false
        filteredMagnitude = 0
        lastPeakTime = 0
        isPeakPhase = false
        dynamicThreshold = 0.15
        magnitudeHistory.removeAll()
        gravityHistory.removeAll()
        accelAmplitudes.removeAll()
        activeSeconds = 0
        recentMagnitudes.removeAll()
    }

    // MARK: - Core Processing

    func processMotionData(_ dataPoint: DataPoint) {
        let timestamp = Double(dataPoint.id) / 1000.0

        // 1. Acceleration magnitude (orientation-agnostic)
        let magnitude = sqrt(
            dataPoint.xAccel * dataPoint.xAccel +
            dataPoint.yAccel * dataPoint.yAccel +
            dataPoint.zAccel * dataPoint.zAccel
        )

        // 2. Low-pass filter to smooth signal
        filteredMagnitude = filterAlpha * magnitude + (1 - filterAlpha) * filteredMagnitude

        // 3. Update rolling history for adaptive threshold
        magnitudeHistory.append(filteredMagnitude)
        if magnitudeHistory.count > historySize {
            magnitudeHistory.removeFirst()
        }

        // 4. Adaptive threshold based on signal statistics
        if magnitudeHistory.count >= 10 {
            let mean = magnitudeHistory.reduce(0, +) / Double(magnitudeHistory.count)
            let variance = magnitudeHistory.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(magnitudeHistory.count)
            let stdDev = sqrt(variance)
            // Threshold adapts to the current signal level — works at any body position
            dynamicThreshold = max(0.06, mean + 0.5 * stdDev)
        }

        // 5. Peak detection → step counting
        detectStep(magnitude: filteredMagnitude, timestamp: timestamp)

        // 6. Movement detection (short window average)
        recentMagnitudes.append(magnitude)
        if recentMagnitudes.count > movementWindowSize {
            recentMagnitudes.removeFirst()
        }
        let avgMagnitude = recentMagnitudes.reduce(0, +) / Double(recentMagnitudes.count)
        isMoving = avgMagnitude > movementThreshold

        // 7. Movement intensity (0-1 scale)
        movementIntensity = min(1.0, avgMagnitude / 1.5)

        // 8. Accumulate active time
        if isMoving {
            activeSeconds += 1.0 / sampleRate
        }

        // 9. Update derived metrics
        updateCalories()
        updateDistance()

        // 10. Wear location classification
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

    // MARK: - Step Detection

    /// Detects steps using peak-crossing on filtered acceleration magnitude.
    /// Validates cadence timing (0.25s–1.5s between steps) to reject noise.
    private func detectStep(magnitude: Double, timestamp: TimeInterval) {
        if !isPeakPhase && magnitude > dynamicThreshold {
            // Rising above threshold — entering peak phase
            isPeakPhase = true
        } else if isPeakPhase && magnitude < dynamicThreshold * 0.65 {
            // Falling below hysteresis band — peak completed
            isPeakPhase = false

            let interval = timestamp - lastPeakTime
            // Walking cadence: ~60-180 steps/min → 0.33s-1.0s per step
            // Allow wider range (0.25-1.5s) for slow/fast gaits
            if lastPeakTime == 0 || (interval > 0.25 && interval < 1.5) {
                stepCount += 1
                lastPeakTime = timestamp
            }
        }
    }

    // MARK: - Calorie Estimation

    /// MET-based calorie estimation from movement intensity.
    private func updateCalories() {
        let met: Double
        if movementIntensity < 0.15 {
            met = 1.3  // sedentary / very light
        } else if movementIntensity < 0.35 {
            met = 3.0  // light walk
        } else if movementIntensity < 0.6 {
            met = 4.5  // moderate walk
        } else if movementIntensity < 0.8 {
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
            strideLength = movementIntensity > 0.5 ? 1.1 : 0.65
        case .chest:
            strideLength = movementIntensity > 0.5 ? 0.95 : 0.60
        case .wrist:
            strideLength = movementIntensity > 0.5 ? 0.85 : 0.55
        case .unknown:
            strideLength = movementIntensity > 0.5 ? 0.80 : 0.55
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

        // Average acceleration amplitude
        let meanAmplitude = accelAmplitudes.reduce(0, +) / Double(accelAmplitudes.count)
        let amplitudeVariance = accelAmplitudes.map { ($0 - meanAmplitude) * ($0 - meanAmplitude) }
            .reduce(0, +) / Double(accelAmplitudes.count)

        // Gravity vector instability (how much it changes between samples)
        var gravityVariance: Double = 0
        for i in 1..<gravityHistory.count {
            let dx = gravityHistory[i].x - gravityHistory[i - 1].x
            let dy = gravityHistory[i].y - gravityHistory[i - 1].y
            let dz = gravityHistory[i].z - gravityHistory[i - 1].z
            gravityVariance += dx * dx + dy * dy + dz * dz
        }
        gravityVariance /= Double(gravityHistory.count - 1)

        if amplitudeVariance > 0.4 && gravityVariance > 0.08 {
            detectedLocation = .ankle
        } else if amplitudeVariance < 0.12 && gravityVariance < 0.015 {
            detectedLocation = .chest
        } else {
            detectedLocation = .wrist
        }
    }
}
