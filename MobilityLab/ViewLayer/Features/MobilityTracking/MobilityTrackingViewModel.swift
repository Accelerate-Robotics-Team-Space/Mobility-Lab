//
//  MobilityTrackingViewModel.swift
//  MobilityLab
//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import HealthKit
import SwiftUI

final class MobilityTrackingViewModel: ObservableObject {
    @Published var steps: Double = 0
    @Published var distance: Double = 0       // meters
    @Published var heartRate: Double = 0       // bpm
    @Published var spO2: Double = 0            // percentage (0-100)
    @Published var calories: Double = 0        // kcal
    @Published var floorsClimbed: Double = 0
    @Published var activeMinutes: Double = 0
    @Published var isWatchConnected: Bool = false
    @Published var isMoving: Bool = false
    @Published var wearLocation: String = ""
    @Published var activities: [ActivityRecord] = []
    @Published var historyActivities: [ActivityRecord] = []
    @Published var selectedHistoryDate: Date = Date()

    @Injected(\.phoneConnectivityService) private var connectivityService
    @Injected(\.workoutRepository) private var workoutRepository

    private let healthStore = HKHealthStore()
    private var timer: Timer?
    private var observerQueries: [HKObserverQuery] = []
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Formatted Values

    var formattedSteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: steps)) ?? "0"
    }

    var formattedDistance: String {
        String(format: "%.2f", distance / 1000.0)
    }

    var formattedHeartRate: String {
        heartRate > 0 ? String(format: "%.0f", heartRate) : "--"
    }

    var formattedSpO2: String {
        spO2 > 0 ? String(format: "%.0f", spO2) : "--"
    }

    var formattedCalories: String {
        String(format: "%.0f", calories)
    }

    var formattedFloors: String {
        String(format: "%.0f", floorsClimbed)
    }

    var formattedActiveMinutes: String {
        String(format: "%.0f", activeMinutes)
    }

    // MARK: - Init

    init() {
        exportStartDate = Calendar.current.date(
            byAdding: .day, value: -7, to: Date()
        ) ?? Date()
        subscribeToWatchData()
        loadActivitiesFromDB()
    }

    // MARK: - Watch Data

    private func subscribeToWatchData() {
        connectivityService.healthDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.handleWatchData(data)
            }
            .store(in: &cancellables)
    }

    private func handleWatchData(_ data: [String: Any]) {
        if let val = data["stepCount"] as? Double { steps = max(steps, val) }
        if let val = data["heartRate"] as? Double, val > 0 { heartRate = val }
        if let val = data["distance"] as? Double { distance = max(distance, val) }
        if let val = data["activeCalories"] as? Double { calories = max(calories, val) }
        if let val = data["flightsClimbed"] as? Double { floorsClimbed = max(floorsClimbed, val) }
        if let val = data["wearLocation"] as? String { wearLocation = val }
        if let val = data["isMoving"] as? Bool { isMoving = val }
        isWatchConnected = true

        // When watch sends a completed activity, add it immediately and refresh from HealthKit
        if data["activityCompleted"] as? Bool == true {
            addActivityFromWatchData(data)
            // Delayed refresh to pick up the HealthKit-saved workout
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.fetchTodayWorkouts()
            }
        }
    }

    private func addActivityFromWatchData(_ data: [String: Any]) {
        guard let startTimeInterval = data["startTime"] as? TimeInterval,
              let endTimeInterval = data["endTime"] as? TimeInterval else { return }

        let startTime = Date(timeIntervalSince1970: startTimeInterval)
        let endTime = Date(timeIntervalSince1970: endTimeInterval)
        let stepsVal = data["stepCount"] as? Double ?? 0
        let distanceVal = data["distance"] as? Double ?? 0
        let hrAvg = data["heartRateAvg"] as? Double ?? 0
        let hrMax = data["heartRateMax"] as? Double ?? 0
        let cals = data["activeCalories"] as? Double ?? 0
        let flights = data["flightsClimbed"] as? Double ?? 0
        let cadenceVal = data["cadence"] as? Double ?? 0
        let location = data["wearLocation"] as? String ?? "wrist"
        let durationSeconds = endTime.timeIntervalSince(startTime)

        // Auto-classify the activity based on HR, cadence, flights, and speed
        let classification = ActivityClassification.classify(
            heartRateAvg: hrAvg,
            cadence: cadenceVal,
            flightsClimbed: flights,
            durationSeconds: durationSeconds,
            distance: distanceVal
        )

        let record = ActivityRecord(
            title: classification.title,
            icon: classification.icon,
            color: classification.color,
            startTime: startTime,
            endTime: endTime,
            steps: stepsVal,
            distance: distanceVal,
            heartRateAvg: hrAvg,
            heartRateMax: hrMax,
            calories: cals,
            flightsClimbed: flights,
            cadence: cadenceVal,
            spO2: 0
        )

        // Avoid duplicates — don't add if an activity with the same start time exists
        if !activities.contains(where: { abs($0.startTime.timeIntervalSince(record.startTime)) < 60 }) {
            activities.append(record)
            activities.sort { $0.startTime < $1.startTime }
        }

        // Persist to GRDB
        let workoutRecord = WorkoutRecord(
            startTime: startTime,
            endTime: endTime,
            steps: stepsVal,
            distance: distanceVal,
            heartRateAvg: hrAvg,
            heartRateMax: hrMax,
            calories: cals,
            flightsClimbed: flights,
            cadence: cadenceVal,
            activityType: classification.rawValue,
            wearLocation: location
        )
        Task {
            let exists = await workoutRepository.hasWorkout(startTime: startTime)
            if !exists {
                _ = try? await workoutRepository.asyncSaveToDB(workoutRecord)
            }
        }
    }

    // MARK: - Load from GRDB

    func loadActivitiesFromDB() {
        Task {
            let records = await workoutRepository.fetchTodayWorkouts()
            let mapped = records.map { $0.toActivityRecord() }
            await MainActor.run {
                self.activities = mapped.sorted { $0.startTime < $1.startTime }
            }
        }
    }

    func loadHistoryForDate(_ date: Date) {
        selectedHistoryDate = date
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(86400)
        Task {
            let records = await workoutRepository.fetchWorkouts(from: startOfDay, to: endOfDay)
            let mapped = records.map { $0.toActivityRecord() }
            await MainActor.run {
                self.historyActivities = mapped.sorted { $0.startTime < $1.startTime }
            }
        }
    }

    // MARK: - Authorization

    func requestAuthorization() {
        connectivityService.activate()

        guard HKHealthStore.isHealthDataAvailable() else { return }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
            HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.workoutType(),
        ]

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, _ in
            guard success else { return }
            DispatchQueue.main.async {
                self?.fetchAllMetrics()
                self?.fetchTodayWorkouts()
                self?.startObserverQueries()
                self?.startPeriodicRefresh()
            }
        }
    }

    // MARK: - Fetch All

    private func fetchAllMetrics() {
        isWatchConnected = connectivityService.isWatchReachable

        fetchTodayCumulativeStat(.stepCount, unit: .count()) { [weak self] value in
            self?.steps = max(self?.steps ?? 0, value)
        }
        fetchTodayCumulativeStat(.distanceWalkingRunning, unit: .meter()) { [weak self] value in
            self?.distance = max(self?.distance ?? 0, value)
        }
        fetchTodayCumulativeStat(.activeEnergyBurned, unit: .kilocalorie()) { [weak self] value in
            self?.calories = max(self?.calories ?? 0, value)
        }
        fetchTodayCumulativeStat(.flightsClimbed, unit: .count()) { [weak self] value in
            self?.floorsClimbed = value
        }
        fetchTodayCumulativeStat(.appleExerciseTime, unit: .minute()) { [weak self] value in
            self?.activeMinutes = value
        }
        fetchLatestSample(.heartRate, unit: HKUnit.count().unitDivided(by: .minute())) { [weak self] value in
            if value > 0 { self?.heartRate = value }
        }
        fetchLatestSample(.oxygenSaturation, unit: .percent()) { [weak self] value in
            if value > 0 { self?.spO2 = value * 100 }
        }
    }

    // MARK: - Periodic Refresh

    private func startPeriodicRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.fetchAllMetrics()
            self?.fetchTodayWorkouts()
        }
    }

    deinit {
        timer?.invalidate()
        observerQueries.forEach { healthStore.stop($0) }
    }

    // MARK: - Activities (HealthKit Workouts)

    private func fetchTodayWorkouts() {
        let workoutType = HKObjectType.workoutType()
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, _ in
            guard let self, let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
                return
            }

            let group = DispatchGroup()
            var records: [ActivityRecord] = []

            for workout in workouts {
                group.enter()
                self.buildActivityRecord(from: workout) { record in
                    records.append(record)
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.activities = records.sorted { $0.startTime < $1.startTime }
            }
        }

        healthStore.execute(query)
    }

    private func buildActivityRecord(from workout: HKWorkout, completion: @escaping (ActivityRecord) -> Void) {
        let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        let durationSeconds = workout.endDate.timeIntervalSince(workout.startDate)

        // Fetch steps, heart rate stats, flights, and SpO2 for the workout time range
        let workoutPredicate = HKQuery.predicateForSamples(
            withStart: workout.startDate, end: workout.endDate, options: .strictStartDate
        )

        let group = DispatchGroup()
        var steps: Double = 0
        var hrAvg: Double = 0
        var hrMax: Double = 0
        var flights: Double = 0
        var spO2Value: Double = 0

        // Fetch steps
        group.enter()
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let stepQuery = HKStatisticsQuery(
                quantityType: stepType, quantitySamplePredicate: workoutPredicate, options: .cumulativeSum
            ) { _, result, _ in
                steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                group.leave()
            }
            healthStore.execute(stepQuery)
        } else { group.leave() }

        // Fetch heart rate samples for avg/max
        group.enter()
        if let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            let hrSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let hrQuery = HKSampleQuery(
                sampleType: hrType, predicate: workoutPredicate,
                limit: HKObjectQueryNoLimit, sortDescriptors: [hrSort]
            ) { _, samples, _ in
                let hrUnit = HKUnit.count().unitDivided(by: .minute())
                let values = (samples as? [HKQuantitySample])?.map { $0.quantity.doubleValue(for: hrUnit) } ?? []
                if !values.isEmpty {
                    hrAvg = values.reduce(0, +) / Double(values.count)
                    hrMax = values.max() ?? 0
                }
                group.leave()
            }
            healthStore.execute(hrQuery)
        } else { group.leave() }

        // Fetch flights climbed
        group.enter()
        if let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) {
            let flightsQuery = HKStatisticsQuery(
                quantityType: flightsType, quantitySamplePredicate: workoutPredicate, options: .cumulativeSum
            ) { _, result, _ in
                flights = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                group.leave()
            }
            healthStore.execute(flightsQuery)
        } else { group.leave() }

        // Fetch SpO2
        group.enter()
        if let spO2Type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) {
            let spO2Sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let spO2Query = HKSampleQuery(
                sampleType: spO2Type, predicate: workoutPredicate,
                limit: 1, sortDescriptors: [spO2Sort]
            ) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    spO2Value = sample.quantity.doubleValue(for: .percent()) * 100
                }
                group.leave()
            }
            healthStore.execute(spO2Query)
        } else { group.leave() }

        group.notify(queue: .main) {
            // Calculate cadence from steps and duration
            let cadence = durationSeconds > 0 ? (steps / durationSeconds) * 60 : 0

            // Auto-classify activity, but prefer HealthKit's type if it's specific
            let classification: ActivityClassification
            switch workout.workoutActivityType {
            case .running:
                classification = .running
            case .stairClimbing:
                classification = .stairClimbing
            default:
                classification = ActivityClassification.classify(
                    heartRateAvg: hrAvg,
                    cadence: cadence,
                    flightsClimbed: flights,
                    durationSeconds: durationSeconds,
                    distance: distance
                )
            }

            let record = ActivityRecord(
                title: classification.title,
                icon: classification.icon,
                color: classification.color,
                startTime: workout.startDate,
                endTime: workout.endDate,
                steps: steps,
                distance: distance,
                heartRateAvg: hrAvg,
                heartRateMax: hrMax,
                calories: calories,
                flightsClimbed: flights,
                cadence: cadence,
                spO2: spO2Value
            )
            completion(record)
        }
    }

    // MARK: - CSV Export

    @Published var exportStartDate = Date()
    @Published var exportEndDate = Date()
    @Published var exportCSVURL: URL?
    @Published var isExporting = false

    func exportActivitiesCSV() {
        isExporting = true
        let start = Calendar.current.startOfDay(for: exportStartDate)
        let end = Calendar.current.startOfDay(
            for: exportEndDate
        ).addingTimeInterval(86400)

        Task {
            let records = await workoutRepository.fetchWorkouts(
                from: start, to: end
            )
            let csv = buildCSV(from: records)
            let url = writeCSVToTempFile(csv)
            await MainActor.run {
                self.exportCSVURL = url
                self.isExporting = false
            }
        }
    }

    private func buildCSV(from records: [WorkoutRecord]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"

        var lines: [String] = []
        lines.append([
            "Date",
            "Start Time",
            "End Time",
            "Duration (min)",
            "Activity Type",
            "Steps",
            "Distance (m)",
            "Calories (kcal)",
            "Avg HR (bpm)",
            "Max HR (bpm)",
            "Flights Climbed",
            "Cadence (spm)",
            "SpO2 (%)",
            "Wear Location",
        ].joined(separator: ","))

        for r in records {
            let duration = r.endTime.timeIntervalSince(r.startTime) / 60.0
            let row = [
                dateFormatter.string(from: r.startTime),
                timeFormatter.string(from: r.startTime),
                timeFormatter.string(from: r.endTime),
                String(format: "%.1f", duration),
                r.activityType,
                String(format: "%.0f", r.steps),
                String(format: "%.1f", r.distance),
                String(format: "%.1f", r.calories),
                String(format: "%.0f", r.heartRateAvg),
                String(format: "%.0f", r.heartRateMax),
                String(format: "%.0f", r.flightsClimbed),
                String(format: "%.0f", r.cadence),
                String(format: "%.0f", r.spO2),
                r.wearLocation,
            ]
            lines.append(row.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    private func writeCSVToTempFile(_ csv: String) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startStr = dateFormatter.string(from: exportStartDate)
        let endStr = dateFormatter.string(from: exportEndDate)
        let fileName = "MobilityLab_\(startStr)_to_\(endStr).csv"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Observer Queries (Real-Time HealthKit Updates)

    private func startObserverQueries() {
        let typesToObserve: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .stepCount,
            .activeEnergyBurned,
            .distanceWalkingRunning,
            .flightsClimbed,
            .appleExerciseTime,
            .oxygenSaturation,
        ]

        for identifier in typesToObserve {
            guard let quantityType = HKQuantityType.quantityType(
                forIdentifier: identifier
            ) else { continue }

            let query = HKObserverQuery(
                sampleType: quantityType,
                predicate: nil
            ) { [weak self] _, _, _ in
                DispatchQueue.main.async {
                    self?.fetchAllMetrics()
                }
            }
            healthStore.execute(query)
            observerQueries.append(query)
        }
    }

    // MARK: - HealthKit Queries

    private func fetchTodayCumulativeStat(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        completion: @escaping (Double) -> Void
    ) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else {
                DispatchQueue.main.async { completion(0) }
                return
            }
            DispatchQueue.main.async {
                completion(sum.doubleValue(for: unit))
            }
        }

        healthStore.execute(query)
    }

    private func fetchLatestSample(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        completion: @escaping (Double) -> Void
    ) {
        guard let quantityType = HKQuantityType.quantityType(
            forIdentifier: identifier
        ) else { return }

        // Query today's samples only to get fresh data from watch
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay, end: nil, options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate, ascending: false
        )
        let query = HKSampleQuery(
            sampleType: quantityType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion(0) }
                return
            }
            DispatchQueue.main.async {
                completion(sample.quantity.doubleValue(for: unit))
            }
        }

        healthStore.execute(query)
    }
}
