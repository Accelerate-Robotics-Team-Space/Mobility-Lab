//
//  MobilityTrackingViewModel.swift
//  SensorSuite
//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import HealthKit
import Foundation

final class MobilityTrackingViewModel: ObservableObject {
    @Published var steps: Double = 0
    @Published var distance: Double = 0       // meters
    @Published var heartRate: Double = 0       // bpm
    @Published var spO2: Double = 0            // percentage (0-100)
    @Published var calories: Double = 0        // kcal
    @Published var floorsClimbed: Double = 0
    @Published var activeMinutes: Double = 0
    @Published var isWatchConnected: Bool = false
    @Published var activities: [ActivityRecord] = []

    @Injected(\.phoneConnectivityService) private var connectivityService

    private let healthStore = HKHealthStore()
    private var timer: Timer?
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
        subscribeToWatchData()
        loadTodayActivities()
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
        if let val = data["stepCount"] as? Double { steps = val }
        if let val = data["heartRate"] as? Double { heartRate = val }
        if let val = data["distance"] as? Double { distance = val }
        if let val = data["activeCalories"] as? Double { calories = val }
        isWatchConnected = true
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
        ]

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, _ in
            guard success else { return }
            DispatchQueue.main.async {
                self?.fetchAllMetrics()
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
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Activities

    private func loadTodayActivities() {
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)

        activities = [
            ActivityRecord(
                title: "Morning Walk",
                icon: "figure.walk",
                color: .indigo1,
                startTime: cal.date(bySettingHour: 7, minute: 15, second: 0, of: today)!,
                endTime: cal.date(bySettingHour: 7, minute: 50, second: 0, of: today)!,
                steps: 3200, distance: 2100, heartRateAvg: 92, heartRateMax: 118, calories: 145, spO2: 98
            ),
            ActivityRecord(
                title: "Stair Climb",
                icon: "figure.stairs",
                color: .tangerine,
                startTime: cal.date(bySettingHour: 9, minute: 30, second: 0, of: today)!,
                endTime: cal.date(bySettingHour: 9, minute: 42, second: 0, of: today)!,
                steps: 680, distance: 320, heartRateAvg: 105, heartRateMax: 132, calories: 62, spO2: 97
            ),
            ActivityRecord(
                title: "Afternoon Run",
                icon: "figure.run",
                color: .green1,
                startTime: cal.date(bySettingHour: 12, minute: 0, second: 0, of: today)!,
                endTime: cal.date(bySettingHour: 12, minute: 35, second: 0, of: today)!,
                steps: 4500, distance: 3800, heartRateAvg: 142, heartRateMax: 168, calories: 320, spO2: 96
            ),
            ActivityRecord(
                title: "Evening Walk",
                icon: "figure.walk",
                color: .cornflower,
                startTime: cal.date(bySettingHour: 17, minute: 30, second: 0, of: today)!,
                endTime: cal.date(bySettingHour: 18, minute: 10, second: 0, of: today)!,
                steps: 4100, distance: 2800, heartRateAvg: 88, heartRateMax: 105, calories: 180, spO2: 98
            ),
        ]
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
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
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
