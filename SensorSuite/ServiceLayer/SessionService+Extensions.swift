//
//  SessionService+Extensions.swift
//  SensorSuite BMM
//
//  Created by Vadym Riznychok on 5/14/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import CoreData
import FactoryKit
import Foundation

/// Delegate for TurnTrackerDriver.swift
protocol SessionPositionDelegate: AnyObject {
    /// Triggers when the position the app thinks the patient is in is updated
    /// - Parameter pos: The position the app thinks the patient is in
    func actualPerceivedPositionUpdated(_ pos: PositionalFlagCategory)

    /// Triggers when any amount of Wearables are connect or ZERO wearables are connected
    /// - Parameter isConnected: Bool indicating if any number of wearables are connected
    func isWearableConnected(_ isConnected: Bool)

    /// Triggers when tracking is toggled on the wearable
    /// - Parameter isTracking: Bool indicating if the wearable is tracking
    func wearableTrackingUpdated(_ isTracking: Bool)

    /// Provides current state of monitoring session
    func monitoringState() -> PatientMonitorState
}

protocol SessionWearableDataPointDelegate: AnyObject {
    /// Trigger when wearble's battery level changed
    /// - Parameter bleId:
    /// - Parameter newBatteryLevel:
    func batteryLvlChanged(from bleId: UUID, _ newBatteryLevel: Int)

    /// Trigger when BMM receives data points from wearable
    /// - Parameter feedResult:
    func dataFeedUpdate(_ feedResult: DataPointResult)
}

/// Delegate for NotificationsCellDriver.swift
protocol SessionNotificationDelegate: AnyObject {
    /// Triggers when a notification is added or removed
    /// - Parameter notifications: Array of session notifications
    func notificationsUpdated(_ notifications: [ALTNotification])
}

protocol PositionToAvoidUpdatedDelegate: AnyObject {
    /// Triggers when position to avoid updated
    func positionToAvoidUpdated()
}

// MARK: - DataPointAnalyzerDelegate
extension SessionService: DataPointAnalyzerDelegate {
    func perceivedActualPositionUpdated(_ position: PositionalFlagCategory) {
        positionDelegate?.actualPerceivedPositionUpdated(position)
    }
}

// MARK: - Static Methods
extension SessionService {
    @available(*, deprecated, renamed: "SessionRepository.getSessionService", message: "Moved to SessionRepository")
    static func getSessionService(
        for patient: ALTPatient,
        router: MqttRouter<DataFeedTopics>,
        turningProto: TurningProtocol,
        posToAvoid: [PositionalFlagCategory],
        container: Container
    ) async throws -> SessionService {
        let sessionRepository = container.sessionRepository.resolve()
        let flags: PositionalFlags = posToAvoid.map(\.flag).combine()
        let newSession = await sessionRepository.getSession(
            patientId: patient.id,
            turningProtocol: turningProto,
            positionsToAvoid: flags
        )
        let sessionService = SessionService(
            currentSession: newSession,
            turningProto: turningProto,
            router: router,
            positionsToAvoid: Set(posToAvoid)
        )
        try await sessionRepository.asyncSaveToDB(newSession)
        return sessionService
    }

    @available(*, deprecated, renamed: "SessionRepository.getSessionService", message: "Moved to SessionRepository")
    static func getSessionService(
        resume sessionID: String,
        router: MqttRouter<DataFeedTopics>,
        container: Container
    ) async throws -> SessionService {
        let sessionRepository = container.sessionRepository.resolve()
        let session = try await sessionRepository.getSession(withID: sessionID)
        let posToAvoid = session.patient?.posToAvoidFromProps() ?? []

        let sessionService = SessionService(
            currentSession: session,
            turningProto: session.turningProtocol,
            router: router,
            positionsToAvoid: Set(posToAvoid)
        )
        return sessionService
    }
}
