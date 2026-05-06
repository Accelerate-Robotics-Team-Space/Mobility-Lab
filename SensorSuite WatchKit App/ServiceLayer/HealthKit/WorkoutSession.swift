//
//  WorkoutSession.swift
//  SensorSuite WatchKit Extension
//
//  Created by Anton Vishnyak on 4/14/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import HealthKit
import WatchKit

protocol WorkoutSessionProtocol: AnyObject {
    func startWorkout()
    func stopWorkout()
    var healthStoreAuth: Bool { get }
    var stepCount: Double { get }
    var heartRate: Double { get }
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
    private(set) var heartRate: Double = 0 // {
//        didSet {
//            logger.debug("Workout Session Heart Rate updated: \(heartRate) ❣️")
//        }
//    }
    
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
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
        
        // The quantity type to write to the health store.
        let typesToShare: Set = [HKQuantityType.workoutType()]
        
        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
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
    
    func startWorkout() {
        guard session?.state != .running else {
            return
        }
		logger.info("⌚️ startworkout, prepare to init")
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
    }
    
    func stopWorkout() {
        guard let session, session.state == .running else {
          return
        }
        logger.info("stopWorkout = \(session.state.rawValue)")
        session.end()
    }
}

// MARK: - Private Extension
private extension WorkoutSession {
    func initWorkout() {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .indoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            logger.error("Unable to create workout session with error \(error.localizedDescription)")
        }
        
        // Setup session and builder.
        session?.delegate = self
        builder?.delegate = self
        
        // Set the workout builder's data source.
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                      workoutConfiguration: config)
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutSession: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            switch type {
            case HKQuantityType.quantityType(forIdentifier: .stepCount):
                let statistics = workoutBuilder.statistics(for: quantityType)
                let stepUnit = HKUnit.count()
                
                stepCount = (statistics?.mostRecentQuantity()?.doubleValue(for: stepUnit)) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let statistics = workoutBuilder.statistics(for: quantityType)
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let value = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                
                heartRate = Double(round(1 * value) / 1)
            default: return
            }
        }
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
        if toState == .ended {
            let toWorkoutState = WorkoutState(using: toState)
            let fromWorkoutState = WorkoutState(using: fromState)
            logger.debug("Workout Session state updated from \(fromWorkoutState.description) to \(toWorkoutState.description)")

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
