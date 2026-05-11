//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

struct PublishableActivityLog: Serializable {
    //    static let dev = PublishableActivityLog()
    let activityLogId: Int64?
    let patientId: String?
    let sessionId: String?
    let actualPositionStarted: Double
    let actualPositionEnded: Double
    let actualPosition: String?
    let startingTargetPosition: String?
    let startingTimeRemaining: Double?
    let endingTimeRemaining: Double?
    let bmmMonitoringState: String?
    let bmmPauseReason: String?
    let isWrongPosition: Bool
    let startBMMState: String?
    let hospitalRoomBedId: String?
    let mqttTopicStr: String?
    let bmmName: String?
    let isSynced: Bool
    let updateId: String?
    let headOfBedAngle: Int?
    let turnAngle: Int?
    let endingTargetPosition: String?

    // MARK: - Init
    #if BMM
    init(
         activityLogId: Int64?,
         patientId: String?,
         sessionId: String?,
         actualPositionStarted: Double,
         actualPositionEnded: Double,
         actualPosition: String?,
         startingTargetPosition: String?,
         startingTimeRemaining: Double?,
         endingTimeRemaining: Double?,
         bmmMonitoringState: String?,
         bmmPauseReason: String?,
         isWrongPosition: Bool,
         startBMMState: String?,
         hospitalRoomBedId: String?,
         mqttTopicStr: String?,
         isSynced: Bool,
         updateId: String?,
         headOfBedAngle: Int?,
         turnAngle: Int?,
         endingTargetPosition: String?,
         bmmName: String
    ) {
        self.activityLogId = activityLogId
        self.patientId = patientId
        self.sessionId = sessionId
        self.actualPositionStarted = actualPositionStarted
        self.actualPositionEnded = actualPositionEnded
        self.actualPosition = actualPosition
        self.startingTargetPosition = startingTargetPosition
        self.startingTimeRemaining = startingTimeRemaining
        self.endingTimeRemaining = endingTimeRemaining
        self.bmmMonitoringState = bmmMonitoringState
        self.bmmPauseReason = bmmPauseReason
        self.isWrongPosition = isWrongPosition
        self.startBMMState = startBMMState
        self.hospitalRoomBedId = hospitalRoomBedId
        self.mqttTopicStr = mqttTopicStr
        self.bmmName = bmmName
        self.isSynced = isSynced
        self.updateId = updateId
        self.headOfBedAngle = headOfBedAngle
        self.turnAngle = turnAngle
        self.endingTargetPosition = endingTargetPosition
    }
    #else
    init(
        activityLogId: Int64?,
        patientId: String?,
        sessionId: String?,
        actualPositionStarted: Double,
        actualPositionEnded: Double,
        actualPosition: String?,
        startingTargetPosition: String?,
        startingTimeRemaining: Double?,
        endingTimeRemaining: Double?,
        bmmMonitoringState: String?,
        bmmPauseReason: String?,
        isWrongPosition: Bool,
        startBMMState: String?,
        hospitalRoomBedId: String?,
        mqttTopicStr: String?,
        isSynced: Bool,
        updateId: String?,
        headOfBedAngle: Int?,
        turnAngle: Int?,
        endingTargetPosition: String?
    ) {
        self.activityLogId = activityLogId
        self.patientId = patientId
        self.sessionId = sessionId
        self.actualPositionStarted = actualPositionStarted
        self.actualPositionEnded = actualPositionEnded
        self.actualPosition = actualPosition
        self.startingTargetPosition = startingTargetPosition
        self.startingTimeRemaining = startingTimeRemaining
        self.endingTimeRemaining = endingTimeRemaining
        self.bmmMonitoringState = bmmMonitoringState
        self.bmmPauseReason = bmmPauseReason
        self.isWrongPosition = isWrongPosition
        self.startBMMState = startBMMState
        self.hospitalRoomBedId = hospitalRoomBedId
        self.mqttTopicStr = mqttTopicStr
        self.bmmName = UserDefaults.standard.defaultingBaseStationFromApple // Deprecated - updated once branches are merged
        self.isSynced = isSynced
        self.updateId = updateId
        self.headOfBedAngle = headOfBedAngle
        self.turnAngle = turnAngle
        self.endingTargetPosition = endingTargetPosition
    }
    #endif
}

// MARK: - Codable
extension PublishableActivityLog: Codable {
    enum CodingKeys: String, CodingKey {
        case activityLogId
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
        case startBMMState
        case hospitalRoomBedId
        case mqttTopicStr
        case bmmName
        case isSynced
        case updateId
        case headOfBedAngle
        case turnAngle
        case endingTargetPosition
    }
}
