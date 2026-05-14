//
//  WorkoutRepository.swift
//  MobilityLab
//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import GRDB

protocol WorkoutRepositoryProtocol: DataStorableRepositoryProtocol where Record == WorkoutRecord {
    func fetchWorkouts(from startDate: Date, to endDate: Date) async -> [WorkoutRecord]
    func fetchTodayWorkouts() async -> [WorkoutRecord]
    func fetchWorkout(healthKitId: String) async -> WorkoutRecord?
    func hasWorkout(startTime: Date) async -> Bool
    func hasWorkoutRecord(startTime: Date) async -> WorkoutRecord?
}

extension Container {
    var workoutRepository: Factory<any WorkoutRepositoryProtocol> {
        self { WorkoutRepository(resolve(\.databaseService)) }.cached
    }
}

final class WorkoutRepository: DataStorableRepository<WorkoutRecord>, WorkoutRepositoryProtocol {

    func fetchWorkouts(from startDate: Date, to endDate: Date) async -> [WorkoutRecord] {
        do {
            return try await grdbService.read { db in
                try WorkoutRecord
                    .filter(Column("startTime") >= startDate && Column("startTime") <= endDate)
                    .order(Column("startTime").desc)
                    .fetchAll(db)
            }
        } catch {
            logger.error("Failed to fetch workouts: \(error.localizedDescription)")
            return []
        }
    }

    func fetchTodayWorkouts() async -> [WorkoutRecord] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return await fetchWorkouts(from: startOfDay, to: Date())
    }

    func fetchWorkout(healthKitId: String) async -> WorkoutRecord? {
        do {
            return try await grdbService.read { db in
                try WorkoutRecord
                    .filter(Column("healthKitWorkoutId") == healthKitId)
                    .fetchOne(db)
            }
        } catch {
            logger.error("Failed to fetch workout by HK ID: \(error.localizedDescription)")
            return nil
        }
    }

    func hasWorkout(startTime: Date) async -> Bool {
        do {
            let count = try await grdbService.read { db in
                try WorkoutRecord
                    .filter(Column("startTime") >= startTime.addingTimeInterval(-60)
                         && Column("startTime") <= startTime.addingTimeInterval(60))
                    .fetchCount(db)
            }
            return count > 0
        } catch {
            return false
        }
    }

    func hasWorkoutRecord(startTime: Date) async -> WorkoutRecord? {
        do {
            return try await grdbService.read { db in
                try WorkoutRecord
                    .filter(Column("startTime") >= startTime.addingTimeInterval(-60)
                         && Column("startTime") <= startTime.addingTimeInterval(60))
                    .fetchOne(db)
            }
        } catch {
            return nil
        }
    }
}
