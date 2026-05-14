//
//  WorkoutSession.swift
//  MobilityLab WatchKit Extension
//
//  Created by Anton Vishnyak on 4/14/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import HealthKit
import WatchKit

protocol WorkoutSessionProtocol: AnyObject {
    var placement: String { get set }
    func startWorkout()
    func stopWorkout()
    var healthStoreAuth: Bool { get }
    var stepCount: Double { get }
    var heartRate: Double { get }
    var heartRateAvg: Double { get }
    var heartRateMax: Double { get }
    var distance: Double { get }
    var activeCalories: Double { get }
    var flightsClimbed: Double { get }
    var currentHealthData: [String: Any] { get }
}

extension Container {
    var workoutSession: Factory<WorkoutSessionProtocol> {
        self { WorkoutSession() }.cached
    }
}

final class WorkoutSession: NSObject, WorkoutSessionProtocol {
    private(set) var healthStoreAuth = false
    private(set) var stepCount: Double = 0 {
        didSet {
			logger.info("Workout Session Step Count updated: \(stepCount) 👟")
        }
    }
    private(set) var heartRate: Double = 0
    private var heartRateSamples: [Double] = []
    var placement: String = "wrist"

    var heartRateAvg: Double {
        guard !heartRateSamples.isEmpty else { return 0 }
        return heartRateSamples.reduce(0, +) / Double(heartRateSamples.count)
    }

    var heartRateMax: Double {
        heartRateSamples.max() ?? 0
    }

    private(set) var distance: Double = 0
    private(set) var activeCalories: Double = 0
    private(set) var flightsClimbed: Double = 0

    @Injected(\.watchConnectivityService) private var connectivityService

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var hrPollTimer: Timer?
    private var workoutStartDate: Date?
    
    enum WorkoutState {
        case notStarted
        case running
        case ended
        case paused
        case prepared
        case stopped
        
        var description: String {
            switch self {
            case .notStarted:
                return "NOT_STARTED"
            case .running:
                return "RUNNING"
            case .ended:
                return "ENDED"
            case .paused:
                return "PAUSED"
            case .prepared:
                return "PREPARED"
            case .stopped:
                return "STOPPED"
            }
        }
        
        init(using hkState: HKWorkoutSessionState) {
            switch hkState {
            case .notStarted: self = .notStarted
            case .running: self = .running
            case .ended: self = .ended
            case .paused: self = .paused
            case .prepared: self = .prepared
            case .stopped: self = .stopped
            @unknown default: self = .notStarted
            }
        }
    }
    
    override init() {
        super.init()
        
        // The quantity types to write to the health store.
        // The workout builder needs share permission for all collected data types.
        let typesToShare: Set<HKSampleType> = [
            HKQuantityType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
        ]

        // The quantity types to read from the health store.
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
            HKObjectType.workoutType(),
        ]

        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { succ, error in
            self.healthStoreAuth = succ
            
            if let error = error {
                logger.error("⌚️ Workout Auth failed with error: \(error.localizedDescription)")
            } else {
                logger.event("⌚️ Workout Auth Success: Authorization Approved, Status= \(self.healthStoreAuth)")
            }
        }
    }
    
    var currentHealthData: [String: Any] {
        [
            "stepCount": stepCount,
            "heartRate": heartRate,
            "heartRateAvg": heartRateAvg,
            "heartRateMax": heartRateMax,
            "distance": distance,
            "activeCalories": activeCalories,
            "flightsClimbed": flightsClimbed,
            "timestamp": Date().timeIntervalSince1970,
        ]
    }

    func startWorkout() {
        guard session?.state != .running else {
            return
        }
		logger.info("⌚️ startworkout, prepare to init, placement: \(placement)")

        // Reset metrics
        stepCount = 0
        heartRate = 0
        heartRateSamples = []
        distance = 0
        activeCalories = 0
        flightsClimbed = 0

        // Initialize our workout
        initWorkout()

        // Start the workout session and begin data collection
        let startDate = Date()
        session?.startActivity(with: startDate)

        builder?.beginCollection(withStart: startDate) { succ, error in
            guard succ && error == nil else {
                logger.error("⌚️ Begin activity failed. \(error?.localizedDescription ?? "") HealthKit Authorization \(self.healthStoreAuth)")
                return
            }

            logger.info("⌚️ Workout activity successfully started")
        }

        // Start fallback heart rate query — reads HR samples directly from HealthKit
        // in case the HKLiveWorkoutBuilder delegate doesn't deliver them
        startHeartRateQuery(from: startDate)

        // Start aggressive HR polling — queries HealthKit every 5 seconds
        // as a last resort if both the builder delegate and anchored query fail
        workoutStartDate = startDate
        startHRPolling()
    }

    func stopWorkout() {
        guard let session, session.state == .running else {
          return
        }
        logger.info("stopWorkout = \(session.state.rawValue)")

        hrPollTimer?.invalidate()
        hrPollTimer = nil

        // Stop the fallback heart rate query
        if let heartRateQuery {
            healthStore.stop(heartRateQuery)
            self.heartRateQuery = nil
        }

        session.end()
    }
}

// MARK: - Private Extension
private extension WorkoutSession {
    func initWorkout() {
        let config = HKWorkoutConfiguration()
        // Use .other + .indoor for non-wrist placements — .walking may reduce
        // HR sampling when the watch detects non-wrist orientation.
        // .other triggers high-frequency HR monitoring regardless of placement.
        if placement != "wrist" {
            config.activityType = .other
            config.locationType = .indoor
        } else {
            config.activityType = .walking
            config.locationType = .outdoor
        }
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            logger.error("Unable to create workout session with error \(error.localizedDescription)")
        }
        
        // Setup session and builder.
        session?.delegate = self
        builder?.delegate = self
        
        // Set the workout builder's data source with explicit collection for all types.
        let dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                  workoutConfiguration: config)
        dataSource.enableCollection(for: HKQuantityType.quantityType(forIdentifier: .heartRate)!, predicate: nil)
        dataSource.enableCollection(for: HKQuantityType.quantityType(forIdentifier: .stepCount)!, predicate: nil)
        dataSource.enableCollection(for: HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!, predicate: nil)
        dataSource.enableCollection(for: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!, predicate: nil)
        dataSource.enableCollection(for: HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!, predicate: nil)
        builder?.dataSource = dataSource
    }

    /// Fallback: query heart rate samples directly from HealthKit using HKAnchoredObjectQuery.
    /// This ensures heart rate is captured even if the HKLiveWorkoutBuilder delegate doesn't deliver it.
    func startHeartRateQuery(from startDate: Date) {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        // Removed HKDevice.local() filter — during active HKWorkoutSession, HR samples
        // from the optical sensor may be tagged with the workout builder's device rather
        // than HKDevice.local(), causing valid HR readings to be silently dropped
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)

        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        heartRateQuery = query
        healthStore.execute(query)
        logger.info("⌚️ Started fallback HKAnchoredObjectQuery for heart rate")
    }

    /// Polls HealthKit every 5 seconds for the latest HR sample.
    /// This is the most reliable method — works regardless of whether
    /// the workout builder or anchored query deliver HR data.
    func startHRPolling() {
        hrPollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.pollLatestHeartRate()
        }
    }

    func pollLatestHeartRate() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let startDate = workoutStartDate else { return }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate, end: nil, options: .strictStartDate
        )
        let sort = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate, ascending: false
        )
        let query = HKSampleQuery(
            sampleType: hrType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [sort]
        ) { [weak self] _, samples, error in
            if let error {
                logger.error("⌚️ HR poll error: \(error.localizedDescription)")
                return
            }
            guard let sample = samples?.first as? HKQuantitySample else {
                logger.debug("⌚️ HR poll: no samples yet")
                return
            }
            let hrUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let value = sample.quantity.doubleValue(for: hrUnit)
            if value > 0 {
                logger.info("⌚️ HR poll got: \(value) bpm")
                self?.heartRate = Double(round(value))
                if let hr = self?.heartRate, hr > 0 {
                    self?.heartRateSamples.append(hr)
                }
            }
        }
        healthStore.execute(query)
    }

    func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let hrSamples = samples as? [HKQuantitySample], !hrSamples.isEmpty else { return }

        let hrUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        for sample in hrSamples {
            let value = sample.quantity.doubleValue(for: hrUnit)
            if value > 0 {
                logger.debug("⌚️ Fallback HR sample: \(value) bpm")
                heartRate = Double(round(value))
                heartRateSamples.append(heartRate)
            }
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutSession: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let typeNames = collectedTypes.compactMap { ($0 as? HKQuantityType)?.identifier }.joined(separator: ", ")
        logger.debug("⌚️ didCollectDataOf types: \(typeNames)")

        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            switch type {
            case HKQuantityType.quantityType(forIdentifier: .stepCount):
                let statistics = workoutBuilder.statistics(for: quantityType)
                stepCount = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let statistics = workoutBuilder.statistics(for: quantityType)
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let value = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                logger.debug("⌚️ Heart rate raw value: \(value), statistics nil: \(statistics == nil), mostRecent nil: \(statistics?.mostRecentQuantity() == nil)")
                heartRate = Double(round(value))
                if heartRate > 0 {
                    heartRateSamples.append(heartRate)
                }
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                let statistics = workoutBuilder.statistics(for: quantityType)
                distance = statistics?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let statistics = workoutBuilder.statistics(for: quantityType)
                activeCalories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .flightsClimbed):
                let statistics = workoutBuilder.statistics(for: quantityType)
                flightsClimbed = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            default: continue
            }
        }

        connectivityService.sendHealthData(currentHealthData)
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Retreive the workout event.
        guard let workoutEventType = workoutBuilder.workoutEvents.last?.type else { return }
        
        // Update the timer based on the event received.
        switch workoutEventType {
        case .motionResumed:
            logger.debug("Workout Resumed")
        case .motionPaused:
            logger.debug("Workout Paused")
        default: return
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutSession: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        let toWorkoutState = WorkoutState(using: toState)
        let fromWorkoutState = WorkoutState(using: fromState)
        logger.info("⌚️ Workout Session state: \(fromWorkoutState.description) → \(toWorkoutState.description)")

        if toState == .ended {

            builder?.endCollection(withEnd: Date()) { success, error in
                if success == false {
                    logger.error("⌚️ Failed to endCollection. \(error?.localizedDescription ?? "")")
                }
                self.builder?.finishWorkout(completion: { workout, error in

                    guard workout != nil && error == nil else {
                        logger.error("⌚️ Failed to finishWorkout. \(error?.localizedDescription ?? "")")
                        return
                    }
                    // reset workout
                    self.session = nil
                    self.builder = nil

                    logger.info("⌚️ Finished Workout!")

                })
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        logger.error("Workout Session Failed. \(error.localizedDescription)")
    }
}
