//
//  ALTActivityLog.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 1/17/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB

struct ALTActivityLog: DataStorable, Hashable {
    private(set) var id: Int64?
    private(set) var actualPositionEnded: Date
    private(set) var actualPosition: String
    private(set) var startingTargetPosition: String
    private(set) var startingTimeRemaining: Double
    private(set) var endingTimeRemaining: Double?
    private(set) var bmmMonitoringState: String?
    private(set) var bmmPauseReason: String?
    private(set) var isWrongPosition: Bool
    private(set) var hospitalRoomBedId: String
    private(set) var mqttTopicStr: String
    private(set) var isSynced: Bool
    private(set) var isCurrent: Bool
    private(set) var updateId: String
    private(set) var headOfBedAngle: Int?
    private(set) var turnAngle: Int?
    private(set) var endingTargetPosition: String?

    let sessionId: String
    let patientId: String
    let actualPositionStarted: Date

    static let timeFormatter = DateComponentsFormatter()

    func publishable(bmmName: String) -> PublishableActivityLog {
        PublishableActivityLog(
            activityLogId: id,
            patientId: patientId,
            sessionId: sessionId,
            actualPositionStarted: actualPositionStarted.timeIntervalSince1970,
            actualPositionEnded: actualPositionEnded.timeIntervalSince1970,
            actualPosition: actualPosition,
            startingTargetPosition: startingTargetPosition,
            startingTimeRemaining: startingTimeRemaining,
            endingTimeRemaining: endingTimeRemaining,
            bmmMonitoringState: bmmMonitoringState,
            bmmPauseReason: bmmPauseReason,
            isWrongPosition: isWrongPosition,
            startBMMState: ["monitoring": bmmMonitoringState, "pause": bmmPauseReason].description,
            hospitalRoomBedId: hospitalRoomBedId,
            mqttTopicStr: mqttTopicStr,
            isSynced: isSynced,
            updateId: updateId,
            headOfBedAngle: headOfBedAngle,
            turnAngle: turnAngle,
            endingTargetPosition: endingTargetPosition,
            bmmName: bmmName
        )
    }

    // MARK: - Init
    init(
        session: ALTSession,
        actualPositionStarted: Date = Date(),
        actualPositionEnded: Date = Date(),
        actualPosition: PositionalFlagCategory,
        startingTarget: PositionalFlagCategory,
        startingTimeRemaining: Double,
        endingTimeRemaining: Double? = nil,
        bmmMonitoringState: String,
        bmmPauseReason: String,
        isWrongPosition: Bool,
        hospitalRoomBedId: String,
        mqttTopicStr: String,
        updateId: String,
        headOfBedAngle: Int?,
        turnAngle: Int?,
        endingTargetPosition: String?,
        mock: Bool = false
    ) {
        self.id = mock ? Int64.random(in: 1...10000) : nil
        self.patientId = session.patientId
        self.sessionId = session.id
        self.actualPositionStarted = actualPositionStarted
        self.actualPositionEnded = actualPositionEnded
        self.actualPosition = actualPosition.encoded
        self.startingTargetPosition = startingTarget.encoded
        self.startingTimeRemaining = startingTimeRemaining
        self.endingTimeRemaining = endingTimeRemaining
        self.bmmMonitoringState = bmmMonitoringState
        self.bmmPauseReason = bmmPauseReason
        self.isWrongPosition = isWrongPosition
        self.hospitalRoomBedId = hospitalRoomBedId
        self.mqttTopicStr = mqttTopicStr
        self.isSynced = false
        self.isCurrent = true
        self.updateId = updateId
        self.headOfBedAngle = headOfBedAngle
        self.turnAngle = turnAngle
        self.endingTargetPosition = endingTargetPosition
    }

    init(
        patientID: String,
        sessionID: String,
        actualPositionStarted: Date = Date(),
        actualPositionEnded: Date = Date(),
        actualPosition: PositionalFlagCategory,
        startingTarget: PositionalFlagCategory,
        startingTimeRemaining: Double,
        endingTimeRemaining: Double?,
        bmmMonitoringState: String,
        bmmPauseReason: String,
        isWrongPosition: Bool,
        hospitalRoomBedID: String,
        mqttTopicStr: String,
        updateID: String,
        headOfBedAngle: Int?,
        turnAngle: Int?,
        endingTargetPosition: String?,
        id: Int64? = nil,
        isCurrent: Bool = true,
        isSynced: Bool = false
    ) {
        self.id = id
        self.patientId = patientID
        self.sessionId = sessionID
        self.actualPositionStarted = actualPositionStarted
        self.actualPositionEnded = actualPositionEnded
        self.actualPosition = actualPosition.encoded
        self.startingTargetPosition = startingTarget.encoded
        self.startingTimeRemaining = startingTimeRemaining
        self.endingTimeRemaining = endingTimeRemaining
        self.bmmMonitoringState = bmmMonitoringState
        self.bmmPauseReason = bmmPauseReason
        self.isWrongPosition = isWrongPosition
        self.hospitalRoomBedId = hospitalRoomBedID
        self.mqttTopicStr = mqttTopicStr
        self.isSynced = isSynced
        self.isCurrent = isCurrent
        self.updateId = updateID
        self.headOfBedAngle = headOfBedAngle
        self.turnAngle = turnAngle
        self.endingTargetPosition = endingTargetPosition
    }

    // MARK: - MutablePersistableRecord

    /// Persistence callback called upon successful insertion.
    ///
    /// grab the auto-incremented id
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    // MARK: - Mutating Update
    mutating func updateActivityLog(endTimeRemaining: Double) {
        self.actualPositionEnded = .now
        self.endingTimeRemaining = endTimeRemaining
        self.isCurrent = false
    }

    mutating func updateActivityLog(isSynced: Bool) {
        self.isSynced = isSynced
    }

    mutating func updateActivitylog(bmmMonitoringState: String, pauseReason: String, headOfBedAngle: Int, turnAngle: Int) {
        self.bmmMonitoringState = bmmMonitoringState
        self.bmmPauseReason = pauseReason
        self.headOfBedAngle = headOfBedAngle
        self.turnAngle = turnAngle
    }

    var duration: TimeInterval {
        actualPositionEnded.timeIntervalSince(actualPositionStarted)
    }
}

// MARK: - Codable
extension ALTActivityLog: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "activityLogId"
        case patientId
        case sessionId
        case actualPositionStarted
        case actualPositionEnded
        case actualPosition
        case startingTargetPosition
        case startingTimeRemaining
        case endingTimeRemaining
        case bmmMonitoringState
        case bmmPauseReason
        case isWrongPosition
        case hospitalRoomBedId
        case mqttTopicStr
        case isSynced
        case isCurrent
        case updateId
        case headOfBedAngle
        case turnAngle
        case endingTargetPosition
    }
}
