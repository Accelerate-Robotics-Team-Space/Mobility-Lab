//
//  SessionService.swift
//  SensorSuite
//
//  Created by Josh Franco on 2/22/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import FactoryKit
import Foundation

protocol SessionServiceProtocol: AnyObject {
    var currentSession: ALTSession { get }
    var turnTrackerInfo: TurnTrackerInfo { get }
    var blePeripheral: any BlePeripheralProtocol { get }
    var patchExpiredTimeInterval: TimeInterval { get set }
    var cacheElapsed: TimeInterval { get set }

    var patchExpirationThreshold: Int { get }
    var activeWearablesArr: [Wearable] { get }
    var posToAvoidArr: [PositionalFlagCategory] { get }
    var notificationsArr: [ALTNotification] { get }
    func feedRequestAnswer(_ answer: Bool, atLocation: WearableLocation)
    func rejectDataFeed(wearableId: String)
    func feedRequestLocationDataPoint(_ answer: Bool, wearableId: String)
    func updateDataFeedStatus(_ isTracking: Bool)
    func unpair()
    func endSession()
    func swapping(_ swapping: Bool, wearableLocation: WearableLocation, calibrationPoint: DataPoint)
    func resetPatchTimer()
    func pausePatchTimer()
    func startPatchTimer()
    func terminatePatchTimer()
    func updatePostToAvoid(_ posToAvoid: [PositionalFlagCategory])
    func setPatchExpirationTimer(newThreshold: Int)
    func updateTurnTrackingInfo(_ log: ALTActivityLog)
    var wearableCache: Set<Wearable> { get }
    var isWearableConnected: Bool { get } 

    var dashboardDriverSessionWearableDelegate: DashboardDriverSessionWearableDelegate? { get set }
    var pmdsWearableDelegate: PatientMonitorDriverWearableDelegate? { get set }
    var positionToAvoidUpdatedDelegate: PositionToAvoidUpdatedDelegate? { get set }
    var dataPointDelegate: SessionWearableDataPointDelegate? { get set }
    var notificationDelegate: SessionNotificationDelegate? { get set }
    var positionDelegate: SessionPositionDelegate? { get set }
}

final class SessionService: SessionServiceProtocol {
    typealias Router = BleDataFeedRouter
    enum Constants {
        static let defaultPatchExpiration: Int = 4 * .secondsPerDay
        static let defaultPatchSnooze: Int = .secondsPerDay
        static let defaultCachePeriod: Int = .secondsPerHour
    }

    // MARK: Services
    private let container: Container
    private let patientManager: PatientManagerProtocol
    let activityLogRepository: any ActivityLogRepositoryProtocol
    let sessionRepository: any SessionRepositoryProtocol
    private let syncManager: SyncManagerProtocol
    private let userDefaults: BMMUserDefaultsServiceProtocol

    private(set) var currentSession: ALTSession
	private(set) var turnTrackerInfo: TurnTrackerInfo {
		didSet {
			setup()
		}
	}
    
    private let turningProto: TurningProtocol
    private let analyzer: DataPointAnalyzer
    let blePeripheral: any BlePeripheralProtocol
    private let router: MqttRouter<DataFeedTopics>
    
    private var notifications: Set<ALTNotification> = [] {
        didSet {
            notificationDelegate?.notificationsUpdated(Array(notifications))
        }
    }
    private var positionsToAvoid: Set<PositionalFlagCategory>
    private var activeWearables: Set<Wearable> = [] {
        didSet {
            print("LLOG \(activeWearables.map { $0.bleCentralId })")
            if activeWearables.isEmpty {
                notifications.insert(.noWearable)
            } else {
                notifications.remove(.noWearable)
            }
        }
    }
    private(set) var wearableCache: Set<Wearable> = []
    private(set) var isWearableConnected: Bool = true {
        didSet {
            positionDelegate?.isWearableConnected(isWearableConnected)
        }
    }
    private var swappingProcess = false {
        didSet {
            dashboardDriverSessionWearableDelegate?.swappingProcess(swappingProcess, wearableLocation)
        }
    }
    private var wearableLocation: WearableLocation = .unknown
    private var calibrationPoint = DataPoint()
    private var patchExpiredTick: Timer?
    private var cacheTick: Timer?
    private var wearablePublisherTick: Timer?
    var patchExpiredTimeInterval: TimeInterval = 0 // Make private protection
    var cacheElapsed: TimeInterval = 0
    
    weak var dashboardDriverSessionWearableDelegate: DashboardDriverSessionWearableDelegate?
    weak var pmdsWearableDelegate: PatientMonitorDriverWearableDelegate?
    weak var positionToAvoidUpdatedDelegate: PositionToAvoidUpdatedDelegate?

    weak var dataPointDelegate: SessionWearableDataPointDelegate?
    weak var notificationDelegate: SessionNotificationDelegate?
    weak var positionDelegate: SessionPositionDelegate?

    private(set) var patchExpirationThreshold: Int = SessionService.Constants.defaultPatchExpiration
    private var patchExpirationSnoozeThreshold: Int = SessionService.Constants.defaultPatchSnooze
    private var deleteCacheTimer = SessionService.Constants.defaultCachePeriod

    // MARK: - Computed Variables
    var activeWearablesArr: [Wearable] {
        Array(activeWearables)
    }
    
    var posToAvoidArr: [PositionalFlagCategory] {
        Array(positionsToAvoid)
    }
    
    var notificationsArr: [ALTNotification] {
        Array(notifications)
    }
    
    // MARK: - Init
    init(
        currentSession: ALTSession,
        container: Container = .shared,
        turnTrackerInfo: TurnTrackerInfo = TurnTrackerInfo(),
        turningProto: TurningProtocol,
        analyzer: DataPointAnalyzer = DataPointAnalyzer(),
        blePeripheral: BlePeripheral<BleDataFeedRouter> = BlePeripheral(for: BleDataFeedRouter.std),
        router: MqttRouter<DataFeedTopics>,
        notifications: Set<ALTNotification> = [],
        positionsToAvoid: Set<PositionalFlagCategory>,
        activeWearables: Set<Wearable> = [],
        wearableCache: Set<Wearable> = [],
        isWearableConnected: Bool = true,
        swappingProcess: Bool = false,
        wearableLocation: WearableLocation = .unknown,
        calibrationPoint: DataPoint = DataPoint(),
        patchExpiredTick: Timer? = nil,
        cacheTick: Timer? = nil,
        wearablePublisherTick: Timer? = nil,
        patchExpiredTimeInterval: TimeInterval = 0,
        cacheElapsed: TimeInterval = 0,
        dashboardDriverSessionWearableDelegate: DashboardDriverSessionWearableDelegate? = nil,
        pmdsWearableDelegate: PatientMonitorDriverWearableDelegate? = nil,
        positionToAvoidUpdatedDelegate: PositionToAvoidUpdatedDelegate? = nil,
        dataPointDelegate: SessionWearableDataPointDelegate? = nil,
        notificationDelegate: SessionNotificationDelegate? = nil,
        positionDelegate: SessionPositionDelegate? = nil,
        patchExpirationThreshold: Int = SessionService.Constants.defaultPatchExpiration,
        patchExpirationSnoozeThreshold: Int = SessionService.Constants.defaultPatchSnooze,
        deleteCacheTimer: Int = SessionService.Constants.defaultCachePeriod
    ) {
        self.container = container
        self.patientManager = container.patientManager.resolve()
        self.activityLogRepository = container.activityLogRepository.resolve()
        self.sessionRepository = container.sessionRepository.resolve()
        self.syncManager = container.syncManager.resolve()
        self.userDefaults = container.userDefaults.resolve()
		self.currentSession = currentSession
		self.turnTrackerInfo = turnTrackerInfo
		self.turningProto = turningProto
		self.analyzer = analyzer
		self.blePeripheral = blePeripheral
		self.router = router
		self.notifications = notifications
		self.positionsToAvoid = positionsToAvoid
		self.activeWearables = activeWearables
		self.wearableCache = wearableCache
		self.isWearableConnected = isWearableConnected
		self.swappingProcess = swappingProcess
		self.wearableLocation = wearableLocation
		self.calibrationPoint = calibrationPoint
		self.patchExpiredTick = patchExpiredTick
		self.cacheTick = cacheTick
		self.wearablePublisherTick = wearablePublisherTick
		self.patchExpiredTimeInterval = patchExpiredTimeInterval
		self.cacheElapsed = cacheElapsed
		self.dashboardDriverSessionWearableDelegate = dashboardDriverSessionWearableDelegate
		self.pmdsWearableDelegate = pmdsWearableDelegate
		self.positionToAvoidUpdatedDelegate = positionToAvoidUpdatedDelegate
		self.dataPointDelegate = dataPointDelegate
		self.notificationDelegate = notificationDelegate
		self.positionDelegate = positionDelegate
		self.patchExpirationThreshold = patchExpirationThreshold
		self.patchExpirationSnoozeThreshold = patchExpirationSnoozeThreshold
		self.deleteCacheTimer = deleteCacheTimer
		self.setup()
	}
	
	fileprivate func setup() {
		self.analyzer.delegate = self
		self.turnTrackerInfo.delegate = self
		self.notifications.insert(.noWearable)
		setupPeripheral()
		self.blePeripheral.start()
	}
    
    // MARK: - Util
    func feedRequestAnswer(_ answer: Bool, atLocation: WearableLocation) {
        let newAnswer = DataFeedInitAnswer(
            isCoupled: answer,
            deviceName: userDefaults.defaultingBaseStationFromApple,
            location: atLocation,
            facilityName: userDefaults.facilityName ?? "Unknown"
        )
        if let blePeripheral = blePeripheral as? BlePeripheral<BleDataFeedRouter> {
            blePeripheral.queueChar(.answerDataFeed(answer: newAnswer))
        }
    }
    
    func rejectDataFeed(wearableId: String) {
        let feed = DataFeedRequest(
            wearableId: wearableId,
            peripheralId: blePeripheral.router.service.uuid.uuidString
        )
        if let blePeripheral = blePeripheral as? BlePeripheral<BleDataFeedRouter> {
            blePeripheral.queueChar(.rejectDataFeed(request: feed))
        }
    }
    
    func feedRequestLocationDataPoint(_ answer: Bool, wearableId: String) {
        let feed = DataFeedRequest(
            wearableId: wearableId,
            peripheralId: blePeripheral.router.service.uuid.uuidString
        )
        if let blePeripheral = blePeripheral as? BlePeripheral<BleDataFeedRouter> {
            blePeripheral.queueChar(.requestCalibrationPoint(request: feed))
        }
    }
    
    func updateDataFeedStatus(_ isTracking: Bool) {
        guard !activeWearables.isEmpty else { return }
        if let blePeripheral = blePeripheral as? BlePeripheral<BleDataFeedRouter> {
            blePeripheral.queueChar(.trackingUpdated(isTracking: isTracking))
        }
    }
    
    func unpair() {
        if wearablePublisherTick != nil {
            wearablePublisherTick?.invalidate()
            wearablePublisherTick = nil
        }
        if let blePeripheral = blePeripheral as? BlePeripheral<BleDataFeedRouter> {
            blePeripheral.queueChar(.requestTerminate(request: JustRequest()))
        }
        blePeripheral.unpair()
    }
    
    func endSession() {
        if wearablePublisherTick != nil {
            wearablePublisherTick?.invalidate()
            wearablePublisherTick = nil
        }
        if let blePeripheral = blePeripheral as? BlePeripheral<BleDataFeedRouter> {
            blePeripheral.queueChar(.requestTerminate(request: JustRequest()))
        }
        blePeripheral.terminate()
        sessionRepository.deleteFromDB(currentSession)
        guard let info = patientManager.turnTrackerInfo else { return } // we need to know the current target
        guard let timeRemaining = info.endDate?.timeIntervalSinceNow else { return } // we need to know the time remaining
        guard let lastActivity = activityLogRepository.withLatestEndDate() else { // the last activity must not already be ended
            return
        }
        var currentActivity = lastActivity
        currentActivity.updateActivityLog(endTimeRemaining: timeRemaining)
        activityLogRepository.syncSaveToDB(currentActivity)
    }
    
    func swapping(_ swapping: Bool, wearableLocation: WearableLocation, calibrationPoint: DataPoint) {
        if wearablePublisherTick != nil {
            wearablePublisherTick?.invalidate()
            wearablePublisherTick = nil
        }
        self.wearableLocation = wearableLocation
        self.calibrationPoint = calibrationPoint
        swappingProcess = swapping
        if swapping {
            blePeripheral.terminate()
            setupPeripheral()
            blePeripheral.start()
        }
    }
    
    func resetPatchTimer() {
        patchExpiredTick?.invalidate()
        patchExpiredTick = nil
        patchExpiredTimeInterval = 0
        patchExpirationSnoozeTimer()
    }
    
    func pausePatchTimer() {
        patchExpiredTick?.invalidate()
        patchExpiredTick = nil
    }
    
    func startPatchTimer() {
        startPatchExpiredTimer()
    }
    
    func terminatePatchTimer() {
        patchExpiredTick?.invalidate()
        patchExpiredTick = nil
        patchExpiredTimeInterval = 0
    }
    
    func updatePostToAvoid(_ posToAvoid: [PositionalFlagCategory]) {
        self.positionsToAvoid = Set(posToAvoid)
        self.positionToAvoidUpdatedDelegate?.positionToAvoidUpdated()
    }
    
    func setPatchExpirationTimer(newThreshold: Int) {
        self.patchExpirationThreshold = newThreshold
    }
    
    private func saveActivityViaGeneric<R: ActivityLogRepositoryProtocol>(_ repo: R, _ activity: ALTActivityLog) {
        repo.syncSaveToDB(activity)
    }
}

// MARK: - Private
private extension SessionService {
    // swiftlint:disable:next function_body_length
    func setupPeripheral() {
        blePeripheral.observeStateUpdate { [weak self] state in
            DispatchQueue.main.async { [weak self] in
                switch state {
                case .unpaired(let id):
                    self?.removeWearable(with: id)
                    self?.isWearableConnected = !(self?.activeWearables.isEmpty)!
                    self?.dashboardDriverSessionWearableDelegate?.cancelScan()
                case .connected(let id, _):
                    if self?.blePeripheral.subscribedChars[id]?.count == 1 {
                        self?.dashboardDriverSessionWearableDelegate?.sensorAttemptToPair(attempingToPair: true)
                        self?.cacheTick?.invalidate()
                        self?.cacheTick = nil
                        self?.cacheElapsed = 0
                        self?.pmdsWearableDelegate?.resumeMonitor()
                        guard let wearableExisted = self?.wearableCache.first(where: { $0.bleCentralId == id }) else { return }
                        self?.activeWearables = [wearableExisted]
                        self?.isWearableConnected = !(self?.activeWearables.isEmpty)!
                        self?.dashboardDriverSessionWearableDelegate?.activeWearablesUpdated(self!.activeWearablesArr)
                    } else if self?.blePeripheral.subscribedChars[id]?.count == 12 {
                        self?.dashboardDriverSessionWearableDelegate?.sensorAttemptToPair(attempingToPair: false)
                        logger.debug("🕸️ Peripheral subscribed to characteristics \(id.uuidString)")
                    }
                case .disconnected(let id):
                    self?.dashboardDriverSessionWearableDelegate?.sensorAttemptToPair(attempingToPair: false)
                    self?.dashboardDriverSessionWearableDelegate?.cancelScan()
                    self?.removeWearableTmp(with: id)
                    self?.isWearableConnected = !(self?.activeWearables.isEmpty)!

                    if self?.cacheTick == nil {
                        self?.cacheTick = .scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                            guard let self = self else {
                                timer.invalidate()
                                return
                            }
                            self.cacheElapsed += timer.timeInterval
                            if self.cacheElapsed >= TimeInterval(self.deleteCacheTimer) && !self.wearableCache.isEmpty {
                                logger.info("Remove all from cache")
                                self.wearableCache.removeAll()
                            }
                        }
                    }
                    if self?.wearablePublisherTick != nil {
                        self?.wearablePublisherTick?.invalidate()
                        self?.wearablePublisherTick = nil
                    }
                default:
                    self?.isWearableConnected = !(self?.activeWearables.isEmpty)!
                    self?.dashboardDriverSessionWearableDelegate?.cancelScan()
                }
            }
        }
        if let blePeripheral = blePeripheral as? BlePeripheral<BleDataFeedRouter> {
            blePeripheral.observeValueUpdate { [weak self] charObj, centralId in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    switch charObj {
                    case .dataFeed(let point):
                        if let wearable = self.activeWearables.first(where: { $0.bleCentralId == centralId }) {
                            let calibratedPoint = point.apply(wearable.calibrationPoint ?? DataPoint())
                            self.analyzer.analyze(calibratedPoint)
                            if self.positionDelegate?.monitoringState() != .onPause {
                                self.router.publish(
                                    .dataObservation(point: calibratedPoint),
                                    to: .dataObservation(
                                        facilityID: userDefaults.facilityId,
                                        baseStationGuid: userDefaults.baseStationGuid,
                                        wearableGuuid: wearable.guuid
                                    )
                                )
                            }
                            self.dataPointDelegate?.dataFeedUpdate(.dataPointResult(response: point))
                            self.syncManager.startSync()
                        } else if self.activeWearables.isEmpty {
                            self.feedRequestAnswer(true, atLocation: .chest)
                        }
                    case .calibrationPoint(let calibrationPoint):
                        self.analyzer.analyze(calibrationPoint)
                        if let wearable = self.activeWearables.first(where: { $0.bleCentralId == centralId }) {
                            wearable.calibrationPoint = calibrationPoint
                            self.dashboardDriverSessionWearableDelegate?.dataFeedUpdate(.calibrationPoint(confirmation: true))
                        } else {
                            self.dashboardDriverSessionWearableDelegate?.dataFeedUpdate(.calibrationPoint(confirmation: false))
                        }
                    case .requestDataFeed(let request):
                        if let connectedId = self.connectedCentralID(), connectedId != centralId {
                            self.rejectDataFeed(wearableId: request.wearableId)
                            return
                        }
                        self.dashboardDriverSessionWearableDelegate?.dataFeedUpdate(.newRequest(request: request))
                    case .confirmDataFeed(let confirmation):
                        guard
                            let wearableId = confirmation.wearableId,
                            let wearableGuuid = confirmation.wearableGuuid else { break }

                        let newWearable = Wearable(
                            id: wearableId,
                            guuid: wearableGuuid,
                            bleId: centralId,
                            version: confirmation.version,
                            location: confirmation.location
                        )
                        if self.swappingProcess {
                            newWearable.calibrationPoint = self.calibrationPoint
                            self.swappingProcess = false
                        }

                        self.startPatchExpiredTimer()
                        self.addWearable(newWearable)
                        self.isWearableConnected = !self.activeWearables.isEmpty
                        self.blePeripheral.appendSubscribedCentrals(newCentral: centralId)
                        self.dashboardDriverSessionWearableDelegate?.dataFeedUpdate(.confirmed(confirmation: confirmation))
                    case .batteryLvl(let batteryLevelData):
                        if let connectedId = self.connectedCentralID(), connectedId != centralId {
                            logger.debug("⌚️ rejeceted \(batteryLevelData.wearableId)")
                            self.rejectDataFeed(wearableId: batteryLevelData.wearableId)
                            return
                        }
                        logger.debug("⌚️ battery updated \(batteryLevelData.wearableId)")
                        let newBatterylvl = Int(batteryLevelData.batteryLvl)
                        self.updateWearableBatLvl(
                            bleId: centralId,
                            batLvl: newBatterylvl
                        )
                        self.dataPointDelegate?.batteryLvlChanged(from: centralId, newBatterylvl)
                        self.isWearableConnected = true
                    case .requestTerminate:
                        if let connectedId = self.connectedCentralID(), connectedId != centralId {
                            return
                        }
                        self.dashboardDriverSessionWearableDelegate?.cancelScan()
                    case .trackingUpdated(let isTracking):
                        self.positionDelegate?.wearableTrackingUpdated(isTracking)
                    case .dismissBatteryLow:
                        self.pmdsWearableDelegate?.dismissBatteryLow()
                    case .answerDataFeed, .requestCalibrationPoint, .terminateAnswer, .rejectDataFeed: break // Do Nothing
                    }
                }
            }
        }
    }

    private func connectedCentralID() -> UUID? {
        if case .connected(let id, _) = self.blePeripheral.state {
            return id
        }
        return nil
    }
    
    // MARK: - Wearables
    func addWearable(_ newWearable: Wearable) {
        let oldWearable = activeWearables.first
        activeWearables = [newWearable]

        if oldWearable?.guuid != newWearable.guuid {
            router.publish(
                .wearableVersion(ver: newWearable.version),
                to: .wearableVersion(
                    facilityID: userDefaults.facilityId,
                    baseStationGuid: userDefaults.baseStationGuid,
                    wearableGuuid: newWearable.guuid
                )
            )
            router.publish(
                .wearableLocation(loc: newWearable.location),
                to: .wearableLocation(
                    facilityID: userDefaults.facilityId,
                    baseStationGuid: userDefaults.baseStationGuid,
                    wearableGuuid: newWearable.guuid
                )
            )

            dashboardDriverSessionWearableDelegate?.activeWearablesUpdated(activeWearablesArr)
        }
    }
    
    func removeWearable(with bleId: UUID) {
        guard let wearableToRemove = activeWearables.first(where: { $0.bleCentralId == bleId }) else { return }
        
        activeWearables.remove(wearableToRemove)
        updateActiveWearables()
    }
    
    func removeWearableTmp(with bleId: UUID) {
        guard let wearableToRemove = activeWearables.first(where: { $0.bleCentralId == bleId }) else { return }
        
        activeWearables.remove(wearableToRemove)
        wearableCache.insert(wearableToRemove)
        updateActiveWearables()
    }
    
    func updateActiveWearables() {
        dashboardDriverSessionWearableDelegate?.activeWearablesUpdated(activeWearablesArr)
    }
    
    func updateWearableBatLvl(bleId: UUID, batLvl: Int) {
        guard
            let wearableIndex = activeWearables.firstIndex(where: { $0.bleCentralId == bleId }) else { return }
        
        let wearable = activeWearables[wearableIndex]
        
        wearable.batteryLvl = batLvl
        
        // Only consider battery is constantly draining, not including case where battery is charging
        // Additionally, percentage changed wont ever be 0 since this func can only be called when
        // the difference is != 0
        if wearable.start == nil && wearable.previousBatteryLvl == nil {
            wearable.start = Date()
            wearable.previousBatteryLvl = batLvl
        } else if wearable.start != nil, wearable.previousBatteryLvl != batLvl {
            let absTimeElapsed = abs(wearable.start!.timeIntervalSinceNow.rounded())
            let batteryPercentageChanged = wearable.previousBatteryLvl! - batLvl
            let timeEstInSeconds = Double(batLvl) * absTimeElapsed / Double(batteryPercentageChanged)
            let timeEstInHours = (timeEstInSeconds / .secondsPerHour).rounded()
            wearable.batteryTimeRemaining = Int(timeEstInHours)
            wearable.start = Date()
            wearable.previousBatteryLvl = batLvl
        }
        wearablePublisherTick?.invalidate()
        wearablePublisherTick = nil
        wearablePublisherTick = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let jsonString = "{\"wearableSerialNumber\":\"\(wearable.id)\", \"wearableBatLvl\":\"\(batLvl)\"}"
            self.router.publish(
                .wearableBatteryLvl(lvl: jsonString),
                to: .wearableBatteryLvl(
                    facilityID: userDefaults.facilityId,
                    baseStationGuid: userDefaults.baseStationGuid,
                    wearableGuuid: self.activeWearables[wearableIndex].guuid
                )
            )
        }
        wearablePublisherTick?.fire()
        dashboardDriverSessionWearableDelegate?.activeWearablesUpdated(activeWearablesArr)
    }
    
    func startPatchExpiredTimer() {
        if patchExpiredTick == nil {
            patchExpiredTick = .scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                self.patchExpiredTimeInterval += timer.timeInterval
                if self.patchExpiredTimeInterval >= TimeInterval(self.patchExpirationThreshold) {
                    self.pmdsWearableDelegate?.wearablePatchExpired()
                }
            }
        }
    }
	
	func patchExpirationSnoozeTimer() {
		if patchExpiredTick == nil {
			patchExpiredTick = .scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
				guard let self = self else {
					timer.invalidate()
					return
				}
				self.patchExpiredTimeInterval += timer.timeInterval
				if self.patchExpiredTimeInterval >= TimeInterval(self.patchExpirationSnoozeThreshold) {
					self.pmdsWearableDelegate?.wearablePatchExpired()
				}
			}
		}
	}
}

extension SessionService: TurnTrackerDelegate {
    func getPositionSequence() -> [PositionalFlagCategory] {
        turningProto.turningSequence.filter { !positionsToAvoid.contains($0) }
    }
}

// MARK: - Update session service with existing session
extension SessionService {
    func updateTurnTrackingInfo(_ log: ALTActivityLog) {
        let remaining = log.endingTimeRemaining ?? userDefaults.turnProtocol!.duration

        self.turnTrackerInfo = TurnTrackerInfo(
            endDate: log.actualPositionEnded.addingTimeInterval(remaining),
            positionalFlagCategory: PositionalFlagCategory(log.startingTargetPosition),
            remainingTime: remaining,
            delegate: self
        )
    }
} // swiftlint:disable:this file_length
