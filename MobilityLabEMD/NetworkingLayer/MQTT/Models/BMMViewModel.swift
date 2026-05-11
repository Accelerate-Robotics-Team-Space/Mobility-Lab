//
//  BMMViewModel.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/25/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import SwiftUI

enum Collapsable {
    case wearable
    case patientDetails
    case positionsToAvoid
    case patientLocation
    case system
    case none
}

class BMMViewModel: ObservableObject, Identifiable {
    static let turnSoonInterval: TimeInterval = 660
    static let wrongPosInterval: TimeInterval = 600
    static let alertSoundInterval: TimeInterval = 60
    static let turnAlertSoundInterval: TimeInterval = 3600

    var id: String
    let deviceId: String
    var timeRemainingAlertColor: Color {
        guard !isOverdue else { return .red1 }
        guard patientState != .overdue else { return .red1 }
        guard patientState != .nonTargetPosition else { return .red1 }
        return currentAlert.primaryTextColor
    }
    @Published var unit: String?
    @Published var roomBed: String? {
        willSet { cardData.roomBed = newValue }
    }
    @Published var bmmState: BMMState = .disconnected {
        willSet { cardData.bmmState = newValue }
        didSet {
            guard !isStatic else { return }
            if bmmState == .disconnected {
                stopTurnTimer()
            }
            if bmmState != oldValue {
                if isMonitoring {
                    startTurnTimer()
                }
                updateAlertLevel()
                if bmmState == .disconnected {
                    startDisconnectedTimer()
                } else {
                    stopDisconnectedTimer()
                }
            }
        }
    }
    @Published var patientState: PatientState? = .unassigned {
        willSet { cardData.patientState = newValue }
        didSet {
            guard oldValue != patientState else { return }
            switch self.patientState {
            case .active:
                cardData.lastSeen?.roomBedNumber = roomBed ?? ""
                stopSwappingTimer()
                if isDisplayingDetails && isShowingTodaysAnalyics {
                    loadAnalyticsData()
                }
            case .noSession, .unassigned, .ready:
                cancellable.removeAll()
                stopSwappingTimer()
                stopWrongPositionTimer()
                analyticsData = BMMAnalyticsData()
            case .swappingSensor:
                cardData.swappingTime = 0
                startSwappingTimer()
            case .swappingPatch:
                cardData.swappingTime = 0
                startSwappingTimer()
            case .overdue:
                if soundOverdue {
                    soundOverdue = false
                    let alertModel = AlertModel(type: AlertModel.AlertType.overdue,
                                                unit: unit ?? "Unknown Unit",
                                                roomBed: roomBed ?? "Unknown RoomBed")
                    if !isStatic && bmmState != .disconnected {
                        NotificationCenter.default.post(name: .bmmAlertNote, object: nil, userInfo: ["model": alertModel])
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + BMMViewModel.turnAlertSoundInterval) { [weak self] in
                        self?.soundOverdue = true
                    }
                }
                stopSwappingTimer()
            case .nonTargetPosition:
                if soundWrongPosition {
                    soundWrongPosition = false
                    let alertModel = AlertModel(type: AlertModel.AlertType.nonTargetPosition,
                                                unit: unit ?? "Unknown Unit",
                                                roomBed: roomBed ?? "Unknown RoomBed")
                    if !isStatic && bmmState != .disconnected {
                        NotificationCenter.default.post(name: .bmmAlertNote, object: nil, userInfo: ["model": alertModel])
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + BMMViewModel.alertSoundInterval) { [weak self] in
                        self?.soundWrongPosition = true
                    }
                }
                stopSwappingTimer()
                if isDisplayingDetails && isShowingTodaysAnalyics {
                    loadAnalyticsData()
                }
            case .turnSoon:
                if soundTurnSoon {
                    soundTurnSoon = false
                    let alertModel = AlertModel(type: AlertModel.AlertType.turnSoon,
                                                unit: unit ?? "Unknown Unit",
                                                roomBed: roomBed ?? "Unknown RoomBed")
                    if !isStatic && bmmState != .disconnected {
                        NotificationCenter.default.post(name: .bmmAlertNote, object: nil, userInfo: ["model": alertModel])
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + BMMViewModel.turnAlertSoundInterval) { [weak self] in
                        self?.soundTurnSoon = true
                    }
                    stopSwappingTimer()
                }
            case .paused:
                stopSwappingTimer()
            case .none:
                stopSwappingTimer()
            }
            if isMonitoring {
                startTurnTimer()
            } else {
                stopTurnTimer()
            }
            updateAlertLevel()
        }
    }
    @Published var isWrongPosition = false {
        didSet {
            if isWrongPosition
                && patientState != .noSession
                && patientState != .ready {
                startWrongPositionTimer()
            }
        }
    }
    @Published var rollAngle: Double = 0 {
        willSet { cardData.rollAngle = newValue }
    }
    @Published var pitchAngle: Double = 0 {
        willSet { cardData.pitchAngle = newValue }
    }
    @Published var batteryPercentage: Int? {
        willSet { cardData.bmmBatteryPercentage = newValue }
        didSet {
            guard oldValue != batteryPercentage else { return }
            guard !isStatic else { return }
            updateBMMState()
        }
    }
    @Published var bmmBatteryTimeRemaining: Int?
    @Published var positionsToAvoid: [PositionalFlagCategory] {
        willSet { cardData.positionsToAvoid = newValue }
    }
    @Published var currentAlert: AlertLevel = .green {
        willSet { cardData.currentAlert = newValue }
    }
    @Published var isOverdue = false {
        willSet { cardData.isOverdue = newValue }
    }
    @Published var wrongPositionAfter10Mins = false
    @Published var currentWearable: WearableViewModel? {
        willSet { cardData.sensorBatteryPercentage = newValue?.batteryPercentage }
    }
    @Published var patientDetailsViewModel: PatientDetailsViewModel?
    @Published var currentlyActiveAndMonitoring = false
    @Published var currentOpening: Collapsable = .none
    @Published var analyticsData: BMMAnalyticsData = .init()
    @Published var sessionStartDate: Date = .now
    @Published var turnProtocol: TurnProtocol
    @Published var complianceAngle: ComplianceAngle
    private var isLoadingAnalytics = false

    var bmmMonitoringState = ""
    var bmmPauseReason = ""

    @Injected(\.bmmInfoAPIService) private var bmmInfoService
    @Injected(\.bmmStateTimeTracker) var timeTracker

    @Published var turningProtocol = TurningProtocol()
    var wrongPositionElapse: TimeInterval = 0 {
        didSet {
            guard !isStatic else { return }
            wrongPositionTimeUpdated()
        }
    }
    var isDisplayingDetails = false {
        didSet {
            if isDisplayingDetails {
                isShowingTodaysAnalyics = true
            } else {
                isShowingTodaysAnalyics = false
            }
        }
    }
    private(set) var isStatic = false
    var isShowingTodaysAnalyics = true
    var isMonitoring: Bool {
        return patientState?.isMonitoring == true && bmmState != .disconnected && cardData.sensorState != .disconnected
    }

    private var cancellable = Set<AnyCancellable>()

    /*
     shouldSound toggle is used to handle case where mqttConnection connects -> disconnects ->
     connect -> .... in quick succession. When that happens shouldSound will be false for 5 seconds
     so alerts will not get repeated
     */
    private var soundOverdue = true
    private var soundTurnSoon = true
    private var soundWrongPosition = true
    private var soundBmmLowBattery = true
    private var soundSensorLowBattery = true
	
	var roomBedInfo: HospitalRoomBed?
	var facilityUnitInfo: HospitalUnitInfo?

    var cardData: BMMCardData

    // MARK: - Init
    init() {
        self.id = "A very long id"
        self.deviceId = "ALT007"
        self.unit = "ICU"
        // Used defer to invoke didSet
        self.cardData = BMMCardData(bmmState: .disconnected,
                                    sensorState: .disconnected,
                                    positionsToAvoid: [],
                                    currentAlert: .green)
        defer {
            self.roomBed = "B123-A"
            self.updateTimeRemaining(TimeInterval(5040))
        }
        self.cardData.currentPos = .other
        self.cardData.targetPos = .other
        self.rollAngle = 15.0
        self.pitchAngle = 0.0
        self.batteryPercentage = 34
        self.positionsToAvoid = []
        self.sessionStartDate = Date()
        self.turnProtocol = .Q2
        self.complianceAngle = .angle20
    }

    init(id: String, deviceId: String, unit: String? = nil, roomBed: String? = nil,
         lastSeen: BMMLastSeen? = nil, bmmState: BMMState = .connected,
         sensorState: SensorState = .disconnected, patientState: PatientState = .unassigned,
         timeRemaining: TimeInterval = 0, turnProtocol: String, complianceAngle: Int, currentPos: PositionalFlagCategory? = nil,
         targetPos: PositionalFlagCategory? = nil,
         rollAngle: Double = 0, pitchAngle: Double = 0, batteryPercentage: Int? = nil,
         positionsToAvoid: [PositionalFlagCategory] = [], sessionStartDate: Date = Date(),
         patientDetailsViewModel: PatientDetailsViewModel,
         isStatic: Bool = false
    ) {
        self.id = id
        self.turnProtocol = TurnProtocol(rawValue: turnProtocol) ?? .Q2
        self.complianceAngle = ComplianceAngle(fromInt: complianceAngle) ?? .angle20
        self.deviceId = deviceId
        self.unit = unit
        self.cardData = BMMCardData(bmmState: bmmState,
                                    sensorState: sensorState,
                                    positionsToAvoid: positionsToAvoid,
                                    currentAlert: .green,
                                    isStatic: isStatic)
        defer {
            self.roomBed = roomBed
            self.cardData.lastSeen = lastSeen
            self.bmmState = bmmState
            self.cardData.sensorState = sensorState
            self.patientState = patientState
            self.updateTimeRemaining(timeRemaining)
        }
        self.cardData.currentPos = currentPos
        self.cardData.targetPos = targetPos
        self.rollAngle = rollAngle
        self.pitchAngle = pitchAngle
        self.batteryPercentage = batteryPercentage
        self.positionsToAvoid = positionsToAvoid
        self.sessionStartDate = sessionStartDate
        self.patientDetailsViewModel = patientDetailsViewModel
        self.isStatic = isStatic
        self.turningProtocol.complianceAngle = self.complianceAngle
        self.turningProtocol.turnProtocol = self.turnProtocol
    }

    // MARK: - Analytics
    func loadAnalyticsData(date: Date = Date(), cleanData: Bool = false) {
        guard isStatic == false else {
            analyticsData = BMMAnalyticsData.mockData()
            return
        }
        guard let facilityId = UserDefaults.standard.facilityId,
              let ummId = UserDefaults.standard.unitMobilityMonitorGuid,
              let sessionId = cardData.lastSeen?.sessionId,
              ![.noSession, .ready, .unassigned].contains(patientState) else {
            logger.warn("Not enough info for analytics request")
            return
        }

        if cleanData {
            analyticsData = BMMAnalyticsData()
        }
        if isLoadingAnalytics {
            cancellable.removeAll()
        }

        let requestData = AnalyticsRequestData(bmmId: id,
                                               facilityId: facilityId,
                                               ummId: ummId,
                                               sessionId: sessionId,
                                               date: DateFormatter.analyticsDateFormatter.string(from: date.endOfDay.addingTimeInterval(1)))

        isLoadingAnalytics = true

        Task(priority: .background) {
            do {
                let data = try await bmmInfoService.fetchAnalytics(with: requestData)
                isLoadingAnalytics = false
                Task { @MainActor [weak self] in
                    self?.analyticsData = data.toAnalyticsData(forDate: date.endOfDay)
                }
            }
        }
    }

    func updateAnalyticsIfNeeded() {
        guard isDisplayingDetails, isShowingTodaysAnalyics, [.active, .nonTargetPosition, .turnSoon, .overdue].contains(patientState) else {
            return
        }

        loadAnalyticsData()
    }
}

extension BMMViewModel: Hashable {
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }

    static func == (lhs: BMMViewModel, rhs: BMMViewModel) -> Bool {
        lhs.id == rhs.id
    }
}

extension BMMViewModel {
    func startWrongPositionTimer() {
        guard !isStatic else { return }
        timeTracker.startWrongPosition { [weak self] in
            self?.wrongPositionElapse += 1
            if self?.isWrongPosition == false {
                self?.resetWrongPositionTimer()
            }
        }
    }

    func stopWrongPositionTimer() {
        guard !isStatic else { return }
        timeTracker.stopWrongPosition()
    }

    func resetWrongPositionTimer() {
        guard !isStatic else { return }
        timeTracker.stopWrongPosition()
        wrongPositionElapse = 0
    }

    func startTurnTimer() {
        guard !isStatic else { return }
        timeTracker.startTurn { [weak self] in
            guard let self else { return }
            if self.patientState == .paused {
                self.stopTurnTimer()
            }

            self.updateTimeRemaining(self.cardData.timeRemaining - 1)
        }
    }
    
    func stopTurnTimer() {
        guard !isStatic else { return }
        timeTracker.stopTurn()
    }

    func startSwappingTimer() {
        guard !isStatic else { return }
		logger.info("start swapping timer called")
        timeTracker.startSwapping {  [weak self] in
            self?.cardData.swappingTime += 1
        }
    }

    func stopSwappingTimer() {
        guard !isStatic else { return }
		logger.info("stopSwappingTimer called")
        timeTracker.stopSwapping()
    }

    func startDisconnectedTimer() {
        guard !isStatic else { return }
        timeTracker.startDisconnected { [weak self] in
            self?.cardData.disconnectedTime += 1
            if self?.cardData.disconnectedTime ?? 0 > 30 && self?.cardData.sensorState != .disconnected {
                logger.error("Sensor marked as disconnected for RoomBed:\(self?.roomBed ?? "-") after 30s timeout")
                self?.update(sensorState: .disconnected)
            }
        }
    }

    func stopDisconnectedTimer() {
        guard !isStatic else { return }
        timeTracker.stopDisconnected()
        cardData.disconnectedTime = 0
    }
}

// MARK: - BMMViewModel Low Battery Utils
extension BMMViewModel {
	private func updateBMMState() {
		guard let batteryLevel = batteryPercentage else { return }
		
		if batteryLevel <= 20 {
			alertBMMLowBattery(batteryLevel)
			bmmState = .lowBattery
			bmmBatteryTimeRemaining = Int((Double(batteryPercentage ?? 0) * 0.18).rounded())
		} else {
            bmmState = .connected
		}
	}
	
	private func alertBMMLowBattery(_ batteryLevel: Int) {
		guard batteryLevel == 10 || batteryLevel == 20 else { return }
		
		let alertModel = AlertModel(
			type: AlertModel.AlertType.bmmLowBattery,
			unit: unit ?? "Unknown Unit",
			roomBed: roomBed ?? "Unknown RoomBed"
		)
		
		if !isStatic && bmmState != .disconnected {
			NotificationCenter.default.post(
				name: .bmmAlertNote,
				object: nil,
				userInfo: ["model": alertModel]
			)
		}
	}
	
	func alertSensorLowBattery() {
        guard cardData.sensorState == .lowBattery else { return }
		guard let batteryLevel = currentWearable?.batteryPercentage,
                batteryLevel == 20 || batteryLevel == 10 else { return }

		let alertModel = AlertModel(
			type: AlertModel.AlertType.sensorLowBattery,
			unit: unit ?? "Unknown Unit",
			roomBed: roomBed ?? "Unknown RoomBed"
		)
		
		if !isStatic && bmmState != .disconnected {
			NotificationCenter.default.post(
				name: .bmmAlertNote,
				object: nil,
				userInfo: ["model": alertModel]
			)
		}
	}
}

extension BMMViewModel {
	var isSwapping: Bool { patientState == .swappingPatch || patientState == .swappingSensor }
}
