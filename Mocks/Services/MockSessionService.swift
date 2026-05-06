//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockSessionService: SessionServiceProtocol {
    var currentSession: ALTSession
    var turnTrackerInfo: TurnTrackerInfo
    var blePeripheral: any BlePeripheralProtocol

    var patchExpiredTimeInterval: TimeInterval = 0
    var cacheElapsed: TimeInterval = 0
    var patchExpirationThreshold: Int = 0
    weak var dashboardDriverSessionWearableDelegate: (any DashboardDriverSessionWearableDelegate)?
    weak var pmdsWearableDelegate: (any PatientMonitorDriverWearableDelegate)?
    weak var positionToAvoidUpdatedDelegate: (any PositionToAvoidUpdatedDelegate)?
    weak var dataPointDelegate: (any SessionWearableDataPointDelegate)?
    weak var notificationDelegate: (any SessionNotificationDelegate)?
    weak var positionDelegate: (any SessionPositionDelegate)?
    var activeWearablesArr: [Wearable] = []
    var posToAvoidArr: [PositionalFlagCategory] = []
    var notificationsArr: [ALTNotification] = []
    var wearableCache: Set<Wearable> = []

    var feedRequestHandler: ((Bool, WearableLocation) -> Void)?
    var rejectDataFeedHandler: ((String) -> Void)?
    var feedRequestLocationDataPointHandler: ((Bool, String) -> Void)?
    var updateDataFeedStatusHandler: ((Bool) -> Void)?
    var unpairHandler: (() -> Void)?
    var endSessionHandler: (() -> Void)?
    var swappingHandler: ((Bool, WearableLocation, DataPoint) -> Void)?
    var resetPatchTimerHandler: (() -> Void)?
    var pausePatchTimerHandler: (() -> Void)?
    var startPatchTimerHandler: (() -> Void)?
    var terminatePatchTimerHandler: (() -> Void)?
    var updatePostToAvoidHandler: (([PositionalFlagCategory]) -> Void)?
    var setPatchExpHandler: ((Int) -> Void)?
    var updateTurnTrackingInfoHandler: ((ALTActivityLog) -> Void)?
    var isWearableConnectedHandler: (() -> Bool)?

    init(
        currentSession: ALTSession,
        turnTrackerInfo: TurnTrackerInfo,
        blePeripheral: any BlePeripheralProtocol = MockBlePeripheral()
    ) {
        self.currentSession = currentSession
        self.turnTrackerInfo = turnTrackerInfo
        self.blePeripheral = blePeripheral
    }

    func feedRequestAnswer(_ answer: Bool, atLocation: WearableLocation) {
        guard let feedRequestHandler else {
            fatalError("feedRequestHandler must be set")
        }
        feedRequestHandler(answer, atLocation)
    }

    func rejectDataFeed(wearableId: String) {
        guard let rejectDataFeedHandler else {
            fatalError("rejectDataFeedHandler must be set")
        }
        rejectDataFeedHandler(wearableId)
    }

    func feedRequestLocationDataPoint(_ answer: Bool, wearableId: String) {
        guard let feedRequestLocationDataPointHandler else {
            fatalError("feedRequestLocationDataPointHandler must be set")
        }
        feedRequestLocationDataPointHandler(answer, wearableId)
    }

    func updateDataFeedStatus(_ isTracking: Bool) {
        guard let updateDataFeedStatusHandler else {
            fatalError("updateDataFeedStatusHandler must be set")
        }
        updateDataFeedStatusHandler(isTracking)
    }

    func unpair() {
        guard let unpairHandler else {
            fatalError("unpairHandler must be set")
        }
        unpairHandler()
    }

    func endSession() {
        guard let endSessionHandler else {
            fatalError("endSessionHandler must be set")
        }
        endSessionHandler()
    }

    func swapping(_ swapping: Bool, wearableLocation: WearableLocation, calibrationPoint: DataPoint) {
        guard let swappingHandler else {
            fatalError("swappingHandler must be set")
        }
        swappingHandler(swapping, wearableLocation, calibrationPoint)
    }

    func resetPatchTimer() {
        guard let resetPatchTimerHandler else {
            fatalError("resetPatchTimerHandler must be set")
        }
        resetPatchTimerHandler()
    }

    func pausePatchTimer() {
        guard let pausePatchTimerHandler else {
            fatalError("pausePatchTimerHandler must be set")
        }
        pausePatchTimerHandler()
    }

    func startPatchTimer() {
        guard let startPatchTimerHandler else {
            fatalError("startPatchTimerHandler must be set")
        }
        startPatchTimerHandler()
    }

    func terminatePatchTimer() {
        guard let terminatePatchTimerHandler else {
            fatalError("terminatePatchTimerHandler must be set")
        }
        terminatePatchTimerHandler()
    }

    func updatePostToAvoid(_ posToAvoid: [PositionalFlagCategory]) {
        guard let updatePostToAvoidHandler else {
            fatalError("updatePostToAvoidHandler must be set")
        }
        updatePostToAvoidHandler(posToAvoid)
    }

    func setPatchExpirationTimer(newThreshold: Int) {
        guard let setPatchExpHandler else {
            fatalError("setPatchExpHandler must be set")
        }
        setPatchExpHandler(newThreshold)
    }

    func updateTurnTrackingInfo(_ log: ALTActivityLog) {
        guard let updateTurnTrackingInfoHandler else {
            fatalError("updateTurnTrackingInfoHandler must be set")
        }
        updateTurnTrackingInfoHandler(log)
    }

    var isWearableConnected: Bool {
        guard let isWearableConnectedHandler else {
            fatalError("isWearableConnectedHandler must be set")
        }
        return isWearableConnectedHandler()
    }
}

// MARK: - DashboardDriverSessionWearableDelegate
extension MockSessionService {
    func updateWearables(_ wearables: [Wearable]) {
        dashboardDriverSessionWearableDelegate?.activeWearablesUpdated(wearables)
    }

    func updateFeed(_ feedResult: DataFeedResult) {
        dashboardDriverSessionWearableDelegate?.dataFeedUpdate(feedResult)
    }

    func swapWearable(_ swapping: Bool, location: WearableLocation) {
        dashboardDriverSessionWearableDelegate?.swappingProcess(swapping, location)
    }

    func sensorPair(attempting: Bool) {
        dashboardDriverSessionWearableDelegate?.sensorAttemptToPair(attempingToPair: attempting)
    }

    func cancelScan() {
        dashboardDriverSessionWearableDelegate?.cancelScan()
    }
}

// MARK: - PatientMonitorDriverWearableDelegate
extension MockSessionService {
    func patchExpired() {
        pmdsWearableDelegate?.wearablePatchExpired()
    }

    func dismissLowBattery() {
        pmdsWearableDelegate?.dismissBatteryLow()
    }

    func resumeMonitoring() {
        pmdsWearableDelegate?.resumeMonitor()
    }

    func pairingSelected() {
        pmdsWearableDelegate?.userDidSelectPairing()
    }
}

// MARK: - PositionToAvoidUpdatedDelegate
extension MockSessionService {
    func positionToAvoidUpdated() {
        positionToAvoidUpdatedDelegate?.positionToAvoidUpdated()
    }
}

// MARK: - SessionPositionDelegate
extension MockSessionService {
    func updateActualPerceivedPosition(_ pos: PositionalFlagCategory) {
        positionDelegate?.actualPerceivedPositionUpdated(pos)
    }

    func updateWearableConnected(_ isConnected: Bool) {
        positionDelegate?.isWearableConnected(isConnected)
    }

    func updateWearableTracking(_ isTracking: Bool) {
        positionDelegate?.wearableTrackingUpdated(isTracking)
    }

    func monitoringState(handler: @escaping ((PatientMonitorState) -> Void)) {
        guard let positionDelegate else {
            fatalError("positionDelegate must be set")
        }
        let state = positionDelegate.monitoringState()
        handler(state)
    }
}

// MARK: - SessionWearableDataPointDelegate
extension MockSessionService {
    func updateBatteryLevel(bleID: UUID, newBatteryLevel: Int) {
        dataPointDelegate?.batteryLvlChanged(from: bleID, newBatteryLevel)
    }

    func updateDataFeed(_ feedResult: DataPointResult) {
        dataPointDelegate?.dataFeedUpdate(feedResult)
    }
}

// MARK: - Null Service
final class NullSessionService: SessionServiceProtocol {
    var isWearableConnected: Bool {
        fatalError("Null Service Should Not Be Used")
    }

    var wearableCache: Set<Wearable> {
        fatalError("Null Service Should Not Be Used")
    }

    var currentSession: ALTSession {
        fatalError("Null Service Should Not Be Used")
    }

    var turnTrackerInfo: TurnTrackerInfo {
        fatalError("Null Service Should Not Be Used")
    }

    var blePeripheral: any BlePeripheralProtocol {
        fatalError("Null Service Should Not Be Used")
    }

    var patchExpiredTimeInterval: TimeInterval {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var cacheElapsed: TimeInterval {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var patchExpirationThreshold: Int {
        fatalError("Null Service Should Not Be Used")
    }

    var activeWearablesArr: [Wearable] {
        fatalError("Null Service Should Not Be Used")
    }

    var posToAvoidArr: [PositionalFlagCategory] {
        fatalError("Null Service Should Not Be Used")
    }

    var notificationsArr: [ALTNotification] {
        fatalError("Null Service Should Not Be Used")
    }

    func feedRequestAnswer(_ answer: Bool, atLocation: WearableLocation) {
        fatalError("Null Service Should Not Be Used")
    }

    func rejectDataFeed(wearableId: String) {
        fatalError("Null Service Should Not Be Used")
    }

    func feedRequestLocationDataPoint(_ answer: Bool, wearableId: String) {
        fatalError("Null Service Should Not Be Used")
    }

    func updateDataFeedStatus(_ isTracking: Bool) {
        fatalError("Null Service Should Not Be Used")
    }

    func unpair() {
        fatalError("Null Service Should Not Be Used")
    }

    func endSession() {
        fatalError("Null Service Should Not Be Used")
    }

    func swapping(_ swapping: Bool, wearableLocation: WearableLocation, calibrationPoint: DataPoint) {
        fatalError("Null Service Should Not Be Used")
    }

    func resetPatchTimer() {
        fatalError("Null Service Should Not Be Used")
    }

    func pausePatchTimer() {
        fatalError("Null Service Should Not Be Used")
    }

    func startPatchTimer() {
        fatalError("Null Service Should Not Be Used")
    }

    func terminatePatchTimer() {
        fatalError("Null Service Should Not Be Used")
    }

    func updatePostToAvoid(_ posToAvoid: [PositionalFlagCategory]) {
        fatalError("Null Service Should Not Be Used")
    }

    func setPatchExpirationTimer(newThreshold: Int) {
        fatalError("Null Service Should Not Be Used")
    }

    func updateTurnTrackingInfo(_ log: ALTActivityLog) {
        fatalError("Null Service Should Not Be Used")
    }

    var dashboardDriverSessionWearableDelegate: (any DashboardDriverSessionWearableDelegate)? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var pmdsWearableDelegate: (any PatientMonitorDriverWearableDelegate)? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var positionToAvoidUpdatedDelegate: (any PositionToAvoidUpdatedDelegate)? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var dataPointDelegate: (any SessionWearableDataPointDelegate)? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var notificationDelegate: (any SessionNotificationDelegate)? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var positionDelegate: (any SessionPositionDelegate)? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }
}
