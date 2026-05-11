// swiftlint:disable file_length
//
//  PatientMonitorDriver.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 11/8/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import SwiftUI

protocol PatientMonitorProtocol: AnyObject {
    func stopTimersAndUpdates()
    func syncLogs() async
    var syncingLogs: [String: LogState] { get set }
    @MainActor func endSession() async
}

final class PatientMonitorDriver: ObservableObject, PatientMonitorProtocol {
    enum MonitorTextMode {
        case paused
        case countdown
    }

    struct ResumeSession {
        let remainingTime: TimeInterval?
        let timeInTurn: TimeInterval
        let desiredPosition: PositionalFlagCategory
    }

    private var didIncrementForThisSession: Bool = false
    @Published var syncingState: SyncingLogsState = .none
    @Published var desiredPosition: PositionalFlagCategory = .left
    @Published var nextDesiredPosition: PositionalFlagCategory = .other
    @Published var actualPosition: PositionalFlagCategory = .other
    @Published var isTrackingStr: String = R.string.localizable.unknown()
    @Published var shouldShowStartNextPositionConfirmation: Bool = true
    @Published var startNextPositionConfirmation: Bool = false
    @Published var forceStartNextPosition: Bool = false
    @Published var showNextPositionNotAvailable: Bool = false
    @Published var retainingPatchAlert: Bool = false
    @Published var countdownStr: String = "0:00:00"
    @Published var pausedTimeStr: String = ""
    @Published var countdownTimer: TimeInterval = 0
    @Published var compliancePercentage: Double = 1.0
    @Published var isCountdownNeg: Bool = false
    @Published var pitchDegree: Double = 0.0
    @Published var rollDegree: Double = 0.0
    @Published var alertQueue = [PatientAlert]()
    @MainActor @Published var syncingLogs: [String: LogState] = [:] {
        didSet {
            syncingLogsUpdateHandler(syncingLogs)
        }
    }
    @Published var currentState: PatientMonitorState = .onStart {
        didSet {
            currentStateUpdateHandler(currentState)
        }
    }
    @Published var isComplying: Bool = true {
        didSet {
            alertQueue(add: !isComplying, alert: .wrongPosition)
        }
    }
    @Published var timeToTurn: Bool = false {
        didSet {
            alertQueue(add: timeToTurn, alert: .timeToTurn(nextPosition: self.nextDesiredPosition))
        }
    }
    @Published var displayRePairSensorAlert: Bool = false {
        didSet {
            alertQueue(addAlways: displayRePairSensorAlert, alert: .rePairSensor)
        }
    }
    @Published var displayPatchExpiredAlert: Bool = false {
        didSet {
            alertQueue(addAlways: displayPatchExpiredAlert, alert: .patchExpired)
        }
    }
    @Published var isWearableConnected = false {
        didSet {
            isWearableConnectedHandler(isWearableConnected, oldValue: oldValue)
        }
    }
    @Published var pauseReason: PauseReason = .null {
        didSet {
            pauseReasonHandler(pauseReason, oldValue: oldValue)
        }
    }
    @Published var sensorBatteryPercentage: Int? {
        didSet {
            sensorBatteryPercentageHandler(sensorBatteryPercentage, oldValue: oldValue)
        }
    }
    @Published var lowBattery: Bool = false
    @Published var showConfig: Bool = false
    @Published var lowBatteryShouldAppear: Bool = true
    @Published var wearableDisconnectedMoreThanHour: Bool = false

    // used for debugging - difference between patient's time-in-turn and displayed remaining time
    @Published var diff: Double = 0

    /// "FeatureFlag" to show extra timers with second accuracy for debugging.
    let showDebugTimers: Bool = false

    private var positionLastSeen: [PositionalFlagCategory: Date] = [:]
    private var zipCancellable: AnyCancellable?

    private lazy var formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .brief
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()
    private lazy var devFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()
    private let positionThreshold: TimeInterval = 0

    private var turnTimer: Timer?
    private var complianceTick: Timer?
    private var updateTick: Timer?
    private var wearableDisconnectTimer: Timer?
    private var swappingTimer: Timer?
    private var pauseTimer: Timer?
    private var pauseDurationTimer: Timer?

    private(set) var lastBroadcast = Date.distantPast
    var timeRemaining: TimeInterval?
    private var timeToTurnWasDisplayed = false
    var resumeSession: ResumeSession?

    private(set) var canInsert = false
    var activityLog: ALTActivityLog?
    private(set) var timeNotCompliant: TimeInterval = 0
    @Published var timeInTurn: TimeInterval = 0
    private(set) var timeToTurnTimer: TimeInterval = 0
    private(set) var wrongPositionDetectedTimer: TimeInterval = 0
    private(set) var notComplyingTime: TimeInterval = 0
    private(set) var wasNonCompliant: Bool = false
    private let calendar: Calendar = .autoupdatingCurrent
    var shouldAutoResume = false
    var userSelectedPairing: Bool = false

    // MARK: Services
    let container: Container
    let activityLogRepository: any ActivityLogRepositoryProtocol
    let activityService: ActivityLogServiceProtocol
    private let firebaseLogger: FirebaseLoggerProtocol
    let mqttService: MQTTServiceProtocol
    private let patchService: PatchTrackingServiceProtocol
    let patientManager: PatientManagerProtocol
    let rollCompliance: RollComplianceProtocol
    let userDefaults: BMMUserDefaultsServiceProtocol
    let updateService: UpdateServiceProtocol

    // MARK: Init
    init(using manager: PatientManagerProtocol? = nil, container: Container = .shared) {
        self.container = container
        self.patientManager = manager ?? container.patientManager.resolve()
        self.activityLogRepository = container.activityLogRepository.resolve()
        self.patchService = container.patchTrackingService.resolve()
        self.firebaseLogger = container.firebaseLogger.resolve()
        self.mqttService = container.mqttService.resolve()
        self.activityService = container.activityLogService.resolve()
        self.userDefaults = container.userDefaults.resolve()
        self.rollCompliance = container.rollCompliance.resolve()
        self.updateService = container.updateService.resolve()

        setDelegates()
        updateTracking()
        isWearableConnected = patientManager.session?.isWearableConnected ?? false
        desiredPosition = info?.getPositionOrder(.current) ?? .other
        nextDesiredPosition = info?.getPositionOrder(.next) ?? .other
        configureBindings()
        resumeLastSession()
    }
}

// MARK: - Computed Variables
extension PatientMonitorDriver {
    // value sent to server
    var turnAngle: Int {
        Int(rollDegree.rounded())
    }

    // value sent to server
    var headOfBedAngle: Int {
        Int(pitchDegree.rounded())
    }

    var patchExpirationThreshold: Int {
        patientManager.session?.patchExpirationThreshold ?? SessionService.Constants.defaultPatchExpiration
    }

    var info: TurnTrackerInfo? {
        patientManager.session?.turnTrackerInfo
    }

    var statusText: String {
        switch currentState {
        case .onStart:
            return ""
        case .onResume:
            return "MONITORING"
        case .onPause:
            let reasonText = (pauseReason == .null) ? "UNKNOWN" : pauseReason.rawValue
            return "PAUSED: \(reasonText)".uppercased()
        }
    }

    var isTracking: Bool {
        info?.isTracking ?? false
    }

    var isNewSession: Bool {
        // Treat as new session before any activity log is created or while onStart
        currentState == .onStart || activityLog == nil
    }

    var allPositions: [PositionalFlagCategory] {
        [.left, .right, .supine]
    }

    private var isInTurnSoon: Bool {
        countdownTimer.rounded() <= Double(TurnThresholds.timeToTurnThreshold) && countdownTimer > 0
    }

    var canMoveToNextPosition: Bool {
        isPositionAvailable(info?.getPositionOrder(.next) ?? .other)
    }

    var textMode: MonitorTextMode {
        if currentState == .onPause && pauseReason != .crash {
            return .paused
        } else {
            return .countdown
        }
    }
}

// MARK: - Tracking
extension PatientMonitorDriver {
    func setTrackingTo(to monitoring: Bool) {
        guard info?.isTracking != monitoring else {
            return
        }

        currentState = monitoring ? .onResume : .onPause
        if canInsert {
            updateLogEndTargetAndSend()
            createNewLog()
            publishLog()
        }
        if monitoring {
            canInsert = true
        }
        info?.toggleTracking(to: monitoring)
        updateTracking()
    }

    func toggleTracking() {
        info?.toggleTracking()
        updateTracking()
    }

    func updateTracking() {
        broadcastTrackingStatus()
        isTrackingStr = isTracking ? R.string.localizable.pauseMonitoring() : R.string.localizable.startMonitoring()

        if isTracking {
            if let remainingTime = info?.remainingTime {
                setNewEndDate(using: remainingTime)
            } else {
                setNewStartDate()
            }

            startTimer(onlyAutoAdvance: !isWearableConnected)
        } else if turnTimer != nil, currentState != .onPause {
            info?.updateRemainingTime()
            stopTimer()
        } else if let remainingTime = info?.remainingTime {
            setNewEndDate(using: remainingTime)
            if isWearableConnected {
                updateUI()
            }
        }
    }

    private func broadcastTrackingStatus() {
        patientManager.session?.updateDataFeedStatus(isTracking)
        lastBroadcast = Date()
    }
}

// MARK: - Position Updates
extension PatientMonitorDriver {
    func updateActualPosition(to pos: PositionalFlagCategory) {
        if currentState == .onStart && actualPosition.isCompliance(with: desiredPosition) && canInsert {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.setTrackingTo(to: true)
            }
        }

        guard pos != self.actualPosition else { return } // Remove duplicates
        guard !patientManager.wearables.isEmpty else { return }

        if canInsert || currentState == .onPause {
            updateLogEndTargetAndSend()
        }
        logger.debug("New Position: \(pos.description)")
        actualPosition = pos
        guard canInsert else {
            return
        }

        if currentState == .onPause {
            // no-op
        } else if currentState == .onResume, pos.isCompliance(with: desiredPosition), isCountdownNeg {
            // If we were overdue, and the patient has now become compliant with the desired target,
            // restart the monitoring window but do not advance the expected target.
            logger.debug("Patient was overdue for turn. Now compliant with desired target.")
            setNewStartDate() // reset info.endDate to TurningProtocol.turnProtocol.duration
            startTimer()
            createNewLog()
            publishLog()

            // Reset compliance metrics when restarting monitoring after overdue
            compliancePercentage = 1.0
            timeNotCompliant = 0
            timeInTurn = 0
            timeToTurnWasDisplayed = true // block 'time to turn' alert
            isComplying = true
            wasNonCompliant = false
            isCountdownNeg = false
            resetWrongPositionDetectedAlert()
            timeToTurnWasDisplayed = false
            updateUI()
        } else if currentState == .onResume, pos.isCompliance(with: nextDesiredPosition), isInTurnSoon {
            logger.debug("Updating to next position. Patient is in turn soon.")
            // Keep pause reason if not actively monitoring (defensive); when onResume it's safe to clear
            if currentState == .onResume {
                pauseReason = .null
            }
            updateLogEndTargetAndSend()

            timeToTurnWasDisplayed = true // block 'time to turn' alert
            info?.updateToNextPos()

            // move to next position
            desiredPosition = info?.getPositionOrder(.current) ?? .other
            nextDesiredPosition = info?.getPositionOrder(.next) ?? .other

            // reset compliance
            compliancePercentage = 1.0
            timeNotCompliant = 0
            timeInTurn = 0
            info?.reset()
            updateTracking()

            if info?.isTracking == false {
                info?.toggleTracking()
            }

            startUpdateTimer()
            createNewLog()
            publishLog()

            // Reset other alerts
            resetWrongPositionDetectedAlert()
            timeToTurn = false
            startNextPositionConfirmation = false
            timeToTurnWasDisplayed = false // unblock 'time to turn' alert
            startTimer()
            resetWrongPositionDetectedAlert()
            updateUI()
        } else {
            startUpdateTimer()
            createNewLog()
            publishLog()
        }
    }

    func startNextPosition() {
        if currentState == .onResume {
            pauseReason = .null
        }
        forceStartNextPosition = true
        timeInTurn = 0
        moveToNextPosition()
        // Reset other alerts
        resetWrongPositionDetectedAlert()
        timeToTurn = false
        startNextPositionConfirmation = false
        timeToTurnWasDisplayed = false
    }

    func moveToNextPosition(triggeredByElapsedTime: Bool = false) {
        // if non compliant don't move to next position
        if self.notComplyingTime >= Double(TurnThresholds.notComplyingThreshold), !forceStartNextPosition {
            return
        }

        if canInsert {
            updateLogEndTargetAndSend()
        }

        info?.updateToNextPos()
        forceStartNextPosition = false

        desiredPosition = info?.getPositionOrder(.current) ?? .other
        nextDesiredPosition = info?.getPositionOrder(.next) ?? .other
        if isWearableConnected {
            timeInTurn = 0
        }

        if !actualPosition.isCompliance(with: desiredPosition), triggeredByElapsedTime {
            isComplying = false
        } else {
            timeToTurnWasDisplayed = false
            compliancePercentage = 1.0
            timeNotCompliant = 0
            info?.reset()
            updateTracking()
        }

        if info?.isTracking == false {
            info?.toggleTracking()
        }

        if canInsert, !patientManager.wearables.isEmpty {
            startUpdateTimer()
            createNewLog()
            publishLog()
        }
    }
}

// MARK: - Timing / Timers
extension PatientMonitorDriver {
    func startUpdateTimer() {
        stopUpdateTimer()
        if updateTick == nil {
            updateTick = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] timer in
                guard let self else {
                    timer.invalidate()
                    return
                }
                self.updateTime()
            }
        }
    }

    private func stopUpdateTimer() {
        updateTick?.invalidate()
        updateTick = nil
    }

    private func updateTime() {
        updateLogEndTargetAndSend()

        guard let startDate = activityLog?.actualPositionStarted else {
            return
        }
        let startDay = calendar.component(.day, from: startDate)
        let today = calendar.component(.day, from: .now)

        if startDay != today, mqttService.status.canSend {
            startUpdateTimer()
            createNewLog()
            publishLog()
        }
    }

    /// - parameter onlyAutoAdvance: This is to be set to `true` in cases such as when the sensor is disconnected.
    /// When set to true, the `timeInTurn` will be updated (as the patient is assumed to be still in the same position),
    /// the auto-turn will still advance, but the patient's true time in a position will no longer be updated.
    private func startTimer(onlyAutoAdvance: Bool = false) {
        stopTimer()

        // Do not run timers while in paused state
        if currentState == .onPause && pauseReason != .crash { return }

        if turnTimer == nil {
            turnTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                if onlyAutoAdvance {
                    self.autoMoveToNextPositionIfNeeded()
                } else {
                    self.info?.updateRemainingTime()
                    self.positionLastSeen[self.desiredPosition] = Date()
                    self.updateUI()
                }
            }
            turnTimer?.fire()
        }

        if complianceTick == nil {
            complianceTick = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }

                self.timeInTurn += timer.timeInterval

                if !rollCompliance.isRollCompliance(self.desiredPosition, with: -self.rollDegree) {
                    self.timeNotCompliant += timer.timeInterval
                    self.wrongPositionDetectedTimer += timer.timeInterval
                    self.notComplyingTime += timer.timeInterval
                } else {
                    self.resetWrongPositionDetectedAlert()
                    self.notComplyingTime = 0
                }

                self.compliancePercentage = (self.timeInTurn - self.timeNotCompliant) / self.timeInTurn
                self.isComplying = self.wrongPositionDetectedTimer < Double(TurnThresholds.notComplyingThreshold)
            }
            complianceTick?.fire()
        }
    }

    func stopTimersAndUpdates() {
        stopTimer()
        stopUpdateTimer()
        stopPausedTimer()
        canInsert = false
        setTrackingTo(to: false)
    }

    private func stopTimer() {
        turnTimer?.invalidate()
        complianceTick?.invalidate()
        turnTimer = nil
        complianceTick = nil
    }
}

// MARK: - Activity Logs
extension PatientMonitorDriver {
    private func setNewStartDate(_ date: Date = Date()) {
        guard let turnProtocol = userDefaults.turnProtocol else {
            return
        }
        info?.endDate = date.addingTimeInterval(turnProtocol.duration)
    }

    private func setNewEndDate(using interval: TimeInterval) {
        info?.endDate = Date().addingTimeInterval(interval)
    }

    func createNewLog() {
        guard let session = patientManager.session,
              let turnProtocol = userDefaults.turnProtocol,
              let hospitalRoomBedId = patientManager.currentPatient?.hospitalRoomBedId else {
            return
        }

        let topic: String
        if let wearable = patientManager.wearables.first {
            topic = DataFeedTopics.sessionObservation(
                facilityID: userDefaults.facilityId,
                baseStationGuid: userDefaults.baseStationGuid,
                wearableGuuid: wearable.guuid
            ).structure
        } else if let wearableFromCache = session.wearableCache.first {
            topic = DataFeedTopics.sessionObservation(
                facilityID: userDefaults.facilityId,
                baseStationGuid: userDefaults.baseStationGuid,
                wearableGuuid: wearableFromCache.guuid
            ).structure
        } else {
            topic = DataFeedTopics.sessionObservation(
                facilityID: userDefaults.facilityId,
                baseStationGuid: userDefaults.baseStationGuid,
                wearableGuuid: UUID.null
            ).structure
        }

        let log = ALTActivityLog(
            session: session.currentSession,
            actualPosition: actualPosition,
            startingTarget: desiredPosition,
            startingTimeRemaining: timeRemaining ?? turnProtocol.duration,
            endingTimeRemaining: timeRemaining,
            bmmMonitoringState: currentState.rawValue,
            bmmPauseReason: pauseReason.rawValue,
            isWrongPosition: !actualPosition.isCompliance(with: desiredPosition),
            hospitalRoomBedId: hospitalRoomBedId,
            mqttTopicStr: topic,
            updateId: UUID().uuidString,
            headOfBedAngle: headOfBedAngle,
            turnAngle: turnAngle,
            endingTargetPosition: nextDesiredPosition.encoded
        )
        set(activityLog: log)
    }

    func set(activityLog: ALTActivityLog) {
        guard canInsert, activityLog.id == nil else {
            self.activityLog = activityLog
            return
        }
        do {
            let logWithID = try activityLogRepository.syncSaveAndFetch(activityLog)
            self.activityLog = logWithID
        } catch {
            logger.error("Could not save activity log: \(error)")
            activityLogRepository.syncSaveToDB(activityLog)
            self.activityLog = activityLog
        }
    }

    func publishLog() {
        guard let activityLog  else { return }
        activityLogRepository.syncSaveToDB(activityLog)
        sendLog()
    }

    private func sendLog() {
        guard let activityLog else { return }
        mqttService.publish(
            activityLog.publishable(bmmName: userDefaults.defaultingBaseStationFromApple).toData(),
            to: activityLog.mqttTopicStr,
            isRetained: false,
            qos: .atLeastOnce
        ) { [weak self] result in
            self?.activityLog?.updateActivityLog(isSynced: result.isSuccess)
            if let log = self?.activityLog {
                self?.activityLogRepository.saveToDB(log)
            }
        }
    }

    func updateLogEndTargetAndSend() {
        let timeRemaining = self.timeRemaining ?? self.userDefaults.turnProtocol?.duration ?? 0
        activityLog?.updateActivityLog(endTimeRemaining: timeRemaining)
        if let log = self.activityLog {
            activityLogRepository.syncSaveToDB(log)
        }
        sendLog()
    }

    func syncLogs() async {
        Task { @MainActor [weak self] in
            self?.syncingLogs = [:]
        }
        if let sessionId = patientManager.sessionId {
            let logs: [ALTActivityLog] = await activityLogRepository.fetchNonSynced(sessionId: sessionId)
            guard !logs.isEmpty else {
                Task { @MainActor [weak self] in
                    self?.syncingLogs = [:]
                }
                return
            }

            for log in logs {
                Task { @MainActor [weak self] in
                    self?.syncingLogs[log.updateId] = .syncing
                }
            }
            let bmmName: String = self.userDefaults.defaultingBaseStationFromApple
            for log in logs {
                var mutableLog = log
                logger.debug("Syncing activity log: \(log.updateId)")
                do {
                    _ = try await self.mqttService.publishAsync(
                        log.publishable(bmmName: bmmName).toData(),
                        to: log.mqttTopicStr,
                        isRetained: false,
                        qos: .atLeastOnce
                    )
                    mutableLog.updateActivityLog(isSynced: true)
                    activityLogRepository.syncSaveToDB(mutableLog)
                    Task { @MainActor [weak self] in
                        self?.syncingLogs[log.updateId] = .synced
                    }
                } catch {
                    logger.debug("Failed to sync activity log: \(error)")
                    mutableLog.updateActivityLog(isSynced: false)
                    activityLogRepository.syncSaveToDB(mutableLog)
                    Task { @MainActor [weak self] in
                        self?.syncingLogs[log.updateId] = .failed
                    }
                }
            }
        } else {
            logger.error("SessionID not present")
            Task { @MainActor [weak self] in
                self?.syncingLogs = [:]
            }
        }
    }

    func createAndSendCurrentCrashLog(started: Date, ended: Date, lastLog: ALTActivityLog) {
        let log = createCrashLog(started: started, ended: ended, lastLog: lastLog)
        self.activityLog = log
        sendLog()
    }
}

// MARK: - Wearables & Swapping
extension PatientMonitorDriver {
    func swapWearable(value: Bool) {
        guard let wearable = patientManager.wearables.first else { return }
        let tmpCalibrationPoint = wearable.calibrationPoint
        let tmpWearableLocation = wearable.location
        shouldAutoResume = true
        lowBatteryShouldAppear = true
        patientManager.session?.swapping(true, wearableLocation: tmpWearableLocation, calibrationPoint: tmpCalibrationPoint ?? DataPoint())
        monitorSwappingTime()
    }

    func resetWearableDisconnectedAlert() {
        guard alertQueue.contains(.sensorDisconnect) || alertQueue.contains(.sensorDisconnectOver1Hour) else {
            return
        }
        alertQueue.removeAll(where: { $0 == .sensorDisconnect || $0 == .sensorDisconnectOver1Hour })
    }

    func unpair() {
        patientManager.session?.unpair()
        lowBatteryShouldAppear = true
        shouldAutoResume = true
    }

    func swappingPatch() {
        logReplacingPatch()
        unpair()
        pauseReason = PauseReason.swappingPatch
        terminatePatchTimer()
        // Reset other alerts
        resetWrongPositionDetectedAlert()
        displayPatchExpiredAlert = false
        timeToTurn = false
        lowBattery = false
        monitorSwappingTime()
        patchService.patchUsed()
    }

    private func logReplacingPatch() {
        activityLog?.updateActivitylog(
            bmmMonitoringState: PatientMonitorState.onPause.rawValue,
            pauseReason: PauseReason.swappingPatch.rawValue,
            headOfBedAngle: headOfBedAngle,
            turnAngle: turnAngle
        )
        if let log = activityLog {
            activityLogRepository.syncSaveToDB(log)
        }
        publishLog()
    }

    func monitorSwappingTime() {
        resetOverdueSwappingAlert()
        self.swappingTimer = Timer.scheduledTimer(
            withTimeInterval: 10 * .secondsPerMinute,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else { return }

            if isWearableConnected {
                resetOverdueSwappingAlert()
            } else {
                alertQueue.append(.longSwapPeriod)
            }
        }
    }

    func resetOverdueSwappingAlert() {
        swappingTimer?.invalidate()
        swappingTimer = nil
        if alertQueue.contains(.longSwapPeriod) {
            alertQueue.removeAll(where: { $0 == .longSwapPeriod })
        }
    }
}

// MARK: - Pausing Utils
extension PatientMonitorDriver {
    func startPausedTimer() {
        stopPausedTimer()
        pausedTimeStr = ""
        pauseDurationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            guard let started = self.activityLog?.actualPositionStarted else {
                self.pausedTimeStr = ""
                return
            }
            let elapsed = max(0, Date().timeIntervalSince(started))
            let minutesString = "+" + (self.formatter.string(from: elapsed)?.insertSpaceAfterDigits() ?? "0 min")
            DispatchQueue.main.async {
                self.pausedTimeStr = minutesString
            }
        }
    }

    func stopPausedTimer() {
        pauseDurationTimer?.invalidate()
        pauseDurationTimer = nil
        pausedTimeStr = ""
    }

    func monitorPauseTime() {
        resetPauseTimer()

        self.pauseTimer = Timer.scheduledTimer(
            withTimeInterval: 2 * .secondsPerHour,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else { return }

            if currentState == .onPause {
                alertQueue.append(.longPausePeriod)
            } else {
                resetPauseTimer()
            }
        }
    }

    func resetPauseTimer() {
        self.pauseTimer?.invalidate()
        self.pauseTimer = nil
        if alertQueue.contains(.longPausePeriod) {
            alertQueue.removeAll(where: { $0 == .longPausePeriod })
        }
    }
}

// MARK: - Util Helper
extension PatientMonitorDriver {
    func startTapped() {
        if let resumeSession {
            apply(resumeSession: resumeSession)
        }
        currentState = .onResume
        setTrackingTo(to: true)
        updateLogEndTargetAndSend()
        createNewLog()
        startUpdateTimer()
    }

    func apply(resumeSession: ResumeSession) {
        self.timeInTurn = resumeSession.timeInTurn
        let timeRemaining = resumeSession.remainingTime ?? userDefaults.turnProtocol?.duration ?? 0
        self.timeRemaining = timeRemaining
        self.patientManager.turnTrackerInfo?.updateRemainingTime(to: timeRemaining)
        self.info?.apply(target: desiredPosition)
        self.desiredPosition = desiredPosition
        self.nextDesiredPosition = info?.getPositionOrder(.next) ?? .other
        self.resumeSession = nil
    }

    @MainActor
    func endSession() async {
        stopUpdateTimer()
        currentState = .onPause
        pauseReason = .endSession
        lowBatteryShouldAppear = true

        updateLogEndTargetAndSend()
        createNewLog()
        sendLog()

        mqttService.publish(
            Data(),
            to: DataFeedTopics.patientInfo(
                facilityID: userDefaults.facilityId,
                baseStationGuid: userDefaults.baseStationGuid
            ).structure,
            isRetained: false,
            qos: .atLeastOnce
        )
        mqttService.publish(
            Data(),
            to: DataFeedTopics.patientLocation(
                facilityID: userDefaults.facilityId,
                baseStationGuid: userDefaults.baseStationGuid
            ).structure,
            isRetained: false,
            qos: .atLeastOnce
        )

        _ = try? await activityLogRepository.deleteAll() // Remove all activity logs from local db to with comply HIPAA
        // End Session, resetting vars
        currentState = .onStart
        pauseReason = .null
        timeToTurnWasDisplayed = false
        userDefaults.unsyncedPatchCount = 0
    }

    private func isPositionAvailable(_ pos: PositionalFlagCategory) -> Bool {
        guard let date = positionLastSeen[pos] else { return true }
        return Date().timeIntervalSince(date) > positionThreshold // You can't change to the same position if not spent at least 45 minutes in other
        // You can't change to the same position if not spent at least positionThreshold in other
    }

    func setTimeToTurnTimer(newThreshold: Int) {
        TurnThresholds.timeToTurnThreshold = newThreshold
    }

    func setNotComplyingThreshold(newThreshold: Int) {
        TurnThresholds.notComplyingThreshold = newThreshold
    }

    func setPatchExpirationThreshold(newThreshold: Int) {
        patientManager.session?.setPatchExpirationTimer(newThreshold: newThreshold)
    }
}

// MARK: - UI Updates
private extension PatientMonitorDriver {
    func updateUIFor(remainingTime: TimeInterval) {
        let remainingRounded = remainingTime.rounded()
        // logger.debug(String(format: "Remaining: %.0f s (%.2f min)", remainingRounded, (remainingRounded / 60)))
        countdownTimer = remainingRounded
        isCountdownNeg = remainingRounded < 0

        showTimeToTurnIfNeeded(for: remainingRounded)
        updateDisplayedCountdownString(for: remainingRounded)
        autoMoveToNextPositionIfNeeded()
    }

    func showTimeToTurnIfNeeded(for remainingTime: TimeInterval) {
        if remainingTime <= Double(TurnThresholds.timeToTurnThreshold) && currentState == .onResume {
            if !timeToTurnWasDisplayed, !timeToTurn {
                timeToTurn = true
            }
            shouldShowStartNextPositionConfirmation = false
        } else {
            timeToTurn = false
            shouldShowStartNextPositionConfirmation = true
        }
    }

    func updateDisplayedCountdownString(for remainingTime: TimeInterval) {
        let suffix = (remainingTime < 0) ? R.string.localizable.over() : R.string.localizable.remaining()
        let timeFormatter = showDebugTimers ? devFormatter : formatter

        // Adding 30s here so that the displayed time remaining shows as:
        //      30 sec remaining, Countdown Text: "1min" (remaining)
        //      29 sec remaining, Countdown Text: "0min" (remaining)
        //     -29 sec remaining, Countdown Text: "0min" (over)
        //     -30 sec remaining, Countdown Text: "1min" (over)
        let padding: TimeInterval = showDebugTimers ? 0 : 30

        guard let countdownString = timeFormatter.string(from: remainingTime.magnitude + padding) else {
            assertionFailure("Could not create a valid time string")
            return
        }

        countdownStr = countdownString + suffix
    }

    // Move to the next target position once the current turn protocol duration has elapsed (Q2/Q3/Q4), regardless of compliance
    func autoMoveToNextPositionIfNeeded() {
        let remainingTime = timeRemaining ?? self.info?.remainingTime ?? countdownTimer
        guard let turnProtocol = userDefaults.turnProtocol else {
            return
        }
        let hasElapsedTurnDuration = (timeInTurn > turnProtocol.duration) && (remainingTime <= 0)
        // Logging
        self.diff = remainingTime - (turnProtocol.duration - timeInTurn)
        // logger.debug(
        //     String(
        //         format: "%@Time In Turn: %@ of %@ (%.1f%%). %@ until auto turn. Time Remaining: %@%@",
        //         hasElapsedTurnDuration ? "Turn duration has elapsed. " : "",
        //         devFormatter.string(from: timeInTurn) ?? "000",
        //         devFormatter.string(from: turnProtocol.duration) ?? "000",
        //         (timeInTurn / turnProtocol.duration) * 100,
        //         devFormatter.string(from: turnProtocol.duration - timeInTurn) ?? "000",
        //         devFormatter.string(from: remainingTime) ?? "000",
        //         (remainingTime - (turnProtocol.duration - timeInTurn)).magnitude < 0.1
        //            ? ""
        //            : String(
        //                format: ", Diff: %.1fs",
        //                remainingTime - (turnProtocol.duration - timeInTurn)
        //            )
        //     )
        // )
        if hasElapsedTurnDuration {
            logger.debug("Auto-turning from \(desiredPosition.description) to next position (\(nextDesiredPosition.description)) due to elapsed turn duration")
            // Only clear pause reason when actively monitoring; preserve reason (e.g., .disconnected) while paused
            if currentState == .onResume {
                pauseReason = .null
            }
            forceStartNextPosition = true
            moveToNextPosition(triggeredByElapsedTime: true)
            // Reset other alerts
            startNextPositionConfirmation = false
        } else {
            // Logging
            // let remaining = turnProtocol.duration - timeInTurn
            // logger.debug(String(format: "Time left in turn: %.0f s (%.2f min)", remaining, remaining / 60))
        }
    }

    func updateUI() {
        guard let endDate = info?.endDate else {
            return
        }

        let nowReference = Date.now.timeIntervalSinceReferenceDate
        let endReference = endDate.timeIntervalSinceReferenceDate
        let reminingReference = endReference - nowReference
        timeRemaining = reminingReference

        updateUIFor(remainingTime: reminingReference)
    }
}

// MARK: - Alert Helpers
extension PatientMonitorDriver {
    func resetAlertsWhenReconnected() {
        resetWearableDisconnectedAlert()
        wearableDisconnectTimer?.invalidate()
        wearableDisconnectTimer = nil
        wearableDisconnectedMoreThanHour = false
        lowBatteryShouldAppear = true
    }

    func resetWrongPositionDetectedAlert() {
        wrongPositionDetectedTimer = 0
        isComplying = true
    }

    func resetTimeToTurnAlert() {
        timeToTurnTimer = 0
        timeToTurn = false
        timeToTurnWasDisplayed = true
    }

    func resetLowBatteryAlert() {
        lowBatteryShouldAppear = false
        if currentState == .onResume || currentState == .onStart {
            lowBattery = false
        } else if currentState == .onPause && !isWearableConnected {
            lowBattery = false
        }
        dismissBatteryLow()
    }

    func resetRePairWearableAlert() {
        displayRePairSensorAlert = false
    }

    func sendAlertToBack() {
        alertQueue.append(alertQueue.removeFirst())
    }

    private func alertQueue(addAlways addToQueue: Bool, alert: PatientAlert) {
        if addToQueue {
            addAlways(alert: alert)
        } else {
            remove(alert: alert)
        }
    }

    private func alertQueue(add addToQueue: Bool, alert: PatientAlert) {
        if addToQueue {
            add(alert: alert)
        } else {
            remove(alert: alert)
        }
    }

    private func addAlways(alert: PatientAlert) {
        if !alertQueue.contains(alert) {
            alertQueue.append(alert)
        }
    }

    private func add(alert: PatientAlert) {
        if isWearableConnected, !alertQueue.contains(alert), pauseReason == .null {
            alertQueue.append(alert)
        }
    }

    private func remove(alert: PatientAlert) {
        guard alertQueue.contains(alert) else {
            return
        }
        alertQueue.removeAll(where: { $0 == alert })
    }
}

// MARK: - Patch Utils
extension PatientMonitorDriver {
    func resetPatchTimer() {
        displayPatchExpiredAlert = false
        patientManager.session?.resetPatchTimer()
    }

    private func pausePatchTimer() {
        patientManager.session?.pausePatchTimer()
    }

    private func resumePatchTimer() {
        patientManager.session?.startPatchTimer()
    }

    private func terminatePatchTimer() {
        displayPatchExpiredAlert = false
        patientManager.session?.terminatePatchTimer()
    }

    func incrementPatchIfNeeded() {
        // Only increment once per fresh session context
        guard isNewSession, didIncrementForThisSession == false else { return }
        patchService.patchUsed()
        didIncrementForThisSession = true
    }

    func handleNoPatchTapped() {
        // Skip counting if currently swapping a patch
        if pauseReason == .swappingPatch { return }
        // Always increase patch count on 'No'
        patchService.patchUsed()
    }
}

// MARK: - Init Helpers
private extension PatientMonitorDriver {
    func setDelegates() {
        patientManager.session?.positionDelegate = self
        patientManager.session?.dataPointDelegate = self
        patientManager.session?.pmdsWearableDelegate = self
        patientManager.session?.positionToAvoidUpdatedDelegate = self
        patientManager.delegate = self
    }

    func configureBindings() {
        zipCancellable = Publishers.Zip($rollDegree, $pitchDegree)
            .throttle(for: 5, scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }

                /// Do not send logs when swapping a patch or swapping a sensor, as they are counted to generate the report and patient should be in monitoring
                if self.pauseReason != .swappingPatch,
                   self.pauseReason != .swappingWearable,
                   self.currentState == .onResume {
                    self.activityLog?.updateActivitylog(
                        bmmMonitoringState: self.currentState.rawValue,
                        pauseReason: self.pauseReason.rawValue,
                        headOfBedAngle: self.headOfBedAngle,
                        turnAngle: self.turnAngle
                    )
                    if let log = self.activityLog {
                        self.activityLogRepository.syncSaveToDB(log)
                    }
                    self.publishLog()
                }
            }
    }

    func resumeLastSession() {
        let lastLog = activityLogRepository.withLatestEndDate()
        if let lastLog,
           lastLog.bmmMonitoringState != PatientMonitorState.onStart.rawValue {
            Task { @MainActor in
                resumePreviousSession(lastLog: lastLog)
            }
        } else if firebaseLogger.didCrashDuringPreviousExecution {
            Task { @MainActor in
                resumePreviousSession(lastLog: lastLog)
            }
        } else {
            logger.debug("No previous session, creating a new Activity Log")
            self.createNewLog()
            self.publishLog()
        }
    }

    @MainActor
    func resumePreviousSession(lastLog: ALTActivityLog?) {
        let logMessage = firebaseLogger.didCrashDuringPreviousExecution ? "Resuming previous session after crash" : "Resuming previous session"
        let timeRemaining: TimeInterval? = lastLog?.endingTimeRemaining ?? self.info?.remainingTime
        self.displayRePairSensorAlert = !isWearableConnected && !updateService.isFirstLaunch
        if let lastLog {
            self.publishBMMDisconnectedLog(lastEndDate: lastLog.actualPositionEnded, log: lastLog)
            // Calculate the time in turn & remaining time from this.
            // We're assuming the patient is still in the same position.
            // However we won't be paired with a sensor yet, so this will need to be adjusted when paired and position is known

            // Time-in-Turn (patient's actual physical time in position) - also used for auto-turn calculations
            let timeInTurn: TimeInterval
            // We'll calculate this based on turn protocol so that the next auto-turn occurs in step with remaining time
            if let timeRemaining, let turnProtocol = userDefaults.turnProtocol {
                timeInTurn = max((turnProtocol.duration - timeRemaining), 0)
            } else {
                timeInTurn = 0
            }
            self.timeInTurn = timeInTurn

            let actualPosition = PositionalFlagCategory(lastLog.actualPosition)
            let desiredPosition = PositionalFlagCategory(lastLog.startingTargetPosition)
            self.actualPosition = actualPosition
            self.info?.apply(target: desiredPosition)
            self.desiredPosition = desiredPosition
            self.nextDesiredPosition = info?.getPositionOrder(.next) ?? .other

            // Store these values for when the user taps start, or the session auto-resumes
            self.resumeSession = ResumeSession(
                remainingTime: timeRemaining,
                timeInTurn: timeInTurn,
                desiredPosition: desiredPosition
            )

            // Logging
            let timeinTurnLogString = formatter.string(from: timeInTurn)?.insertSpaceAfterDigits() ?? "\(timeInTurn)"
            let logString1 = "\(logMessage) :: Time-in-Turn: \(timeinTurnLogString.replacingOccurrences(of: ".", with: ""))"
            let remainingTimeString = self.formatter.string(from: timeRemaining ?? 0)?.insertSpaceAfterDigits() ?? "0 min"
            let logString2 = "Remaining Time: \(remainingTimeString.replacingOccurrences(of: ".", with: ""))"
            let logString3 = "Actual Pos: \(actualPosition.description), Desired Pos: \(desiredPosition.description)"
            logger.info([logString1, logString2, logString3].joined(separator: ", "))
        }
        self.currentState = .onPause
        self.pauseReason = .crash
        self.timeRemaining = timeRemaining
        self.updateUIFor(remainingTime: timeRemaining ?? 0)
        self.shouldAutoResume = true
        self.startUpdateTimer()
        if lastLog == nil {
            self.createNewLog()
            self.publishLog()
            logger.info(logMessage)
        }
    }
}

// MARK: - Variable Update Handlers
private extension PatientMonitorDriver {
    @MainActor
    func syncingLogsUpdateHandler(_ syncingLogs: [String: LogState]) {
        if syncingLogs.contains(where: { $0.value == .syncing }) {
            DispatchQueue.main.async { [weak self] in
                self?.syncingState = .syncing
            }
        } else if !syncingLogs.contains(where: { $0.value == .syncing })
                    && syncingLogs.contains(where: { $0.value == .failed }) {
            DispatchQueue.main.async { [weak self] in
                self?.syncingState = .failed
            }
        } else if syncingLogs.filter({ $0.value == .synced }).count == syncingLogs.count {
            DispatchQueue.main.async { [weak self] in
                self?.syncingState = .none
            }
        }
    }

    func currentStateUpdateHandler(_ currentState: PatientMonitorState) {
        switch currentState {
        case .onPause:
            if isWearableConnected {
                // pausePatchTimer()
                stopTimer()
                startPausedTimer()
                alertQueue.removeAll()
            } else {
                if pauseReason != .swappingPatch && pauseReason != .swappingWearable
                   && pauseReason == .null && pauseReason != .endSession && currentState != .onStart {
                    pauseReason = .disconnected
                }
            }
        case .onResume:
            stopPausedTimer()
            pauseReason = .null
            resumePatchTimer()
            resetPauseTimer()
        case .onStart:
            stopPausedTimer()
            resetPauseTimer()
        }
    }

    func displayPatchExpiredAlertUpdateHandler(_ displayPatchExpiredAlert: Bool) {
        if displayPatchExpiredAlert, !alertQueue.contains(.patchExpired) {
            alertQueue.append(.patchExpired)
        } else if !displayPatchExpiredAlert, alertQueue.contains(.patchExpired) {
            alertQueue.removeAll(where: { $0 == .patchExpired })
        }
    }

    func sensorBatteryPercentageHandler(_ sensorBatteryPercentage: Int?, oldValue: Int?) {
        guard let batteryPercentage = sensorBatteryPercentage else { return }
        guard sensorBatteryPercentage != oldValue else { return }
        lowBattery = batteryPercentage <= 20

        if lowBattery {
            if (batteryPercentage == 20 || batteryPercentage == 10) && isWearableConnected {
                resetLowBatteryAlert()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.alertQueue.append(.sensorLowBattery)
                }
            }
        } else {
            if alertQueue.contains(.sensorLowBattery) {
                alertQueue.removeAll(where: { $0 == .sensorLowBattery })
            }
        }
    }

    func isWearableConnectedHandler(_ isWearableConnected: Bool, oldValue: Bool) {
        if isWearableConnected {
            resumePatchTimer()
            resetAlertsWhenReconnected()
            resetOverdueSwappingAlert()
            startTimer()
            // After reconnection, immediately update and publish a log so timers are correct without waiting for movement.
            if currentState == .onResume {
                updateLogEndTargetAndSend()
                createNewLog()
                publishLog()
            }
        } else {
            // pausePatchTimer()

            if oldValue != isWearableConnected {
                // If not swapping, set a meaningful pause reason prior to pausing
                if pauseReason != .swappingPatch && pauseReason != .swappingWearable && pauseReason == .null
                    && pauseReason != .endSession && currentState != .onStart {
                    pauseReason = .disconnected
                    userSelectedPairing = false
                }
                if currentState != .onStart {
                    currentState = .onPause
                    startPausedTimer()
                }
                startTimer(onlyAutoAdvance: true)

                if pauseReason != .swappingPatch && pauseReason != .swappingWearable {
                    if !alertQueue.contains(.sensorDisconnect) {
                        alertQueue.append(.sensorDisconnect)
                    }
                }
                if wearableDisconnectTimer == nil {
                    wearableDisconnectTimer = Timer.scheduledTimer(withTimeInterval: .secondsPerHour, repeats: false, block: { [weak self] timer in
                        if self?.alertQueue.contains(.sensorDisconnect) != true,
                           self?.alertQueue.contains(.sensorDisconnectOver1Hour) != true {
                            self?.alertQueue.append(.sensorDisconnectOver1Hour)
                        }
                        self?.wearableDisconnectedMoreThanHour = true
                        timer.invalidate()
                    })
                }
            }
        }
    }

    func pauseReasonHandler(_ pauseReason: PauseReason, oldValue: PauseReason) {
        if pauseReason.shouldMonitor, pauseReason != oldValue {
            monitorPauseTime()
        }
        // Reflect pause reason changes in the current activity log even while paused
        if pauseReason != .null {
            // End current log with updated pause reason and immediately start a new log to reflect the state change
            updateLogEndTargetAndSend()
            createNewLog()
            publishLog()
        }
    }
}

private extension MQTTSessionStatus {
    var canSend: Bool {
        switch self {
        case .closed, .error, .disconnected:    false
        case .connected, .connecting:           true
        }
    }
}

private extension PauseReason {
    var shouldMonitor: Bool {
        switch self {
        case .pause, .patientRequest, .caregiverRequest,
             .sleep, .surgery, .patientInChair,
             .physicalTherapy, .outOfBedMobility:           true
        case .swappingWearable, .swappingPatch,
             .correctPatient, .disconnected, .endSession,
             .crash, .null:                                 false
        }
    }
}
