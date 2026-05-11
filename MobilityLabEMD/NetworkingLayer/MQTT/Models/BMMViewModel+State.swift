//
//  BMMViewModel+State.swift
//  MobilityLabEMD
//
//  Created by Vadym Riznychok on 5/2/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import Foundation

// MARK: - Handle BMM lifecycle
extension BMMViewModel {

    var isLostSignal: Bool {
        bmmState == .disconnected ||
        (cardData.sensorState == .disconnected &&
         patientState != .swappingPatch &&
         patientState != .swappingSensor)
    }

    func wrongPositionTimeUpdated() {
        guard isWrongPosition else { return }
        switch patientState {
        case .nonTargetPosition, .overdue, .noSession, .ready:
            break
        default:
            patientState = .nonTargetPosition
        }
    }

    func updateTimeRemaining(_ time: TimeInterval) {
        cardData.timeRemaining = time
        isOverdue = time > 0 ? false : true
        guard [.active, .turnSoon, .overdue].contains(patientState) else {
            return
        }

        if time <= 0 {
            patientState = .overdue
        } else if time <= BMMViewModel.turnSoonInterval,
                  time > 0 {
            patientState = .turnSoon
        }
    }

    func update(data dataStr: String, topic: String) {
        switch topic {
        case "battery_level":
            batteryLevelUpdated(dataStr)
        case "location":
            locationUpdated(dataStr)
        case "session_observation":
            sessionUpdated(dataStr)
        case "patient":
            guard let patientData = try? JSONDecoder().decode(PublishablePatient.self, from: dataStr.toData()) else { return }
            updatePatientFromPatientInfo(patientData.toPatientInfo())
        default:
            return
        }
    }

    func update(roll: Double? = nil, pitch: Double? = nil) {
        rollAngle = roll ?? rollAngle
        pitchAngle = pitch ?? pitchAngle

        currentlyActiveAndMonitoring = true
        update(isAlive: true)
        if bmmState != .lowBattery {
			bmmState = .connected
        }
		
        if cardData.sensorState != .lowBattery {
            update(sensorState: .connected)
        }

        if patientState == .noSession,
           !bmmPauseReason.contains("End Session") {
            patientState = .ready
        }
    }
    
    func update(wearable: WearableViewModel, newBatteryLevel: Int) {
        currentWearable = wearable
        currentWearable?.wearableState = patientState?.isMonitoring == true ? .monitoring : .paused
        currentWearable?.alive = true

		updateBatteryLevel(newBatteryLevel)
    }

    func update(isAlive: Bool) {
        self.cardData.isAlive = isAlive
        guard !isStatic else { return }
        if isAlive {
            timeTracker.startIsAlive { [weak self] in
                if self?.cardData.isAlive == false {
                    self?.bmmState = .disconnected
                    self?.timeTracker.stopIsAlive()
                    logger.info("BMM RoomBed:\(self?.roomBed ?? "-") marked as disconnected due to heartbeat timeout")
                }
                self?.cardData.isAlive = false
            }
        }
    }

    func update(sensorState: SensorState) {
        let isNew = sensorState != self.cardData.sensorState
        self.cardData.sensorState = sensorState
        guard !isStatic else { return }

        if sensorState == .disconnected {
            stopTurnTimer()
        }

        if isNew {
            if isMonitoring {
                startTurnTimer()
            }
            updateAlertLevel()
            if sensorState == .disconnected {
                startDisconnectedTimer()
            } else {
                stopDisconnectedTimer()
            }
        }
    }
}

// MARK: - Handle data update
extension BMMViewModel {
    private func update(room: String?) {
        roomBed = room
        guard !isStatic else { return }

        guard let roomBed = roomBed,
              !roomBed.isEmpty else {
            cardData.currentPos = nil
            cardData.targetPos = nil
            roomBed = "UNASSIGNED"
            patientState = .unassigned
            return
        }

        if patientState == .unassigned,
           roomBed != "UNASSIGNED" {
            patientState = .noSession
        }
    }
    
    private func batteryLevelUpdated(_ levelStr: String) {
        guard let level = Int(levelStr) else { return }

        currentlyActiveAndMonitoring = true
        update(isAlive: true)
        batteryPercentage = level
		
        if bmmState != .lowBattery {
			bmmState = .connected
        }
    }

    private func locationUpdated(_ locationStr: String) {
        guard let decodedJson = try? JSONDecoder().decode(HospitalRoomBed.self, from: locationStr.toData()) else { return}

        let allUnit = HospitalUnitInfo.getAll()
        let unitItem = allUnit.first { $0.id == decodedJson.facilityUnitId }
        unit = unitItem?.name
        update(room: decodedJson.roomBedNumber)
    }

    private func sessionUpdated(_ sessionDataStr: String) {
		do {
			let sessionData = try JSONDecoder().decode(PublishableActivityLog.self, from: sessionDataStr.toData())
            bmmMonitoringState = sessionData.bmmMonitoringState ?? ""
            bmmPauseReason = sessionData.bmmPauseReason ?? ""

            cardData.lastSeen?.sessionId = sessionData.sessionId
			logger.info("status: \(bmmMonitoringState), \(bmmPauseReason), \(roomBed ?? "UNASSINGED"), \(sessionStartDate)")
            cardData.currentPos = PositionalFlagCategory(sessionData.actualPosition ?? "Unknown")
            cardData.targetPos = PositionalFlagCategory(sessionData.startingTargetPosition ?? "Unknown")
			isWrongPosition = sessionData.isWrongPosition

			if let roomBedId = sessionData.hospitalRoomBedId {
				fetchAndUpdateRoomBed(id: roomBedId)
			}

            updatePatientStateFromSession()

			if bmmMonitoringState == "onResume" {
				let currentDate = Date()
				let timeElapsed = currentDate.timeIntervalSince1970 - (sessionData.actualPositionStarted)
				wrongPositionElapse = timeElapsed
				
                updateTimeRemaining((sessionData.startingTimeRemaining ?? 0) + 30 - timeElapsed) // Additional 30 seconds for offset with BMM
			} else {
                updateTimeRemaining((sessionData.startingTimeRemaining ?? 0) + 30)
			}
			
			if bmmMonitoringState == "onPause" {
				updateTimer(sessionData.actualPositionStarted, bmmPauseReason)
                cardData.pausedTime = Date().timeIntervalSince1970 - sessionData.actualPositionStarted
			} else {
                cardData.pausedTime = 0
            }
			updateAnalyticsIfNeeded()
		} catch {
			logger.error(error.localizedDescription)
		}
    }
	
	func updateTimer(_ startTime: TimeInterval, _ pauseReason: String) {
		let elapsedTime = Date().timeIntervalSince1970 - startTime
        switch pauseReason {
        case "Swapping Patch", "Replacing Patch", "Swapping Sensor", "Swapping Wearable", "Swapping":
            cardData.swappingTime = elapsedTime
        case "Sensor Disconnected":
            cardData.disconnectedTime = elapsedTime
            if cardData.disconnectedTime > 30 && cardData.sensorState != .disconnected {
                update(sensorState: .disconnected)
            }
        default:
            break
        }
	}

    func fillFrom(bmmStatus: BMMStatus) {
        self.bmmMonitoringState = bmmStatus.bmmMonitoringState ?? ""
        self.bmmPauseReason = bmmStatus.bmmPauseReason ?? ""
        self.batteryPercentage = bmmStatus.bmmBatteryLevel
        self.cardData.rollAngle = Double(bmmStatus.turnAngle)
        self.cardData.pitchAngle = Double(bmmStatus.headOfBedAngle)
        self.cardData.sensorBatteryPercentage = bmmStatus.sensorBatteryLevel
        self.cardData.bmmBatteryPercentage = bmmStatus.bmmBatteryLevel
        if bmmState != .disconnected {
            update(isAlive: true)
        }

        sessionStartDate = DateFormatter.regDateFormatter.date(from: bmmStatus.sessionStartTime) ?? Date()

        update(room: bmmStatus.roomBed)
        unit = bmmStatus.facilityUnitName

        logger.info("status: \(bmmMonitoringState), \(bmmPauseReason), \(roomBed ?? "UNASSINGED"), \(sessionStartDate)")
        
        updatePatientFromPatientInfo(bmmStatus.patientInfo)

        cardData.currentPos = PositionalFlagCategory(bmmStatus.actualPosition)
        cardData.targetPos = PositionalFlagCategory(bmmStatus.startingTargetPosition)
        isWrongPosition = bmmStatus.isWrongPosition
        updatePatientStateFromSession()

        if bmmMonitoringState == "onResume" {
            let actualPositionStarted = DateFormatter.regDateFormatter.date(from: bmmStatus.actualPositionStarted)
            let currentDate = Date()
            let timeElapsed = currentDate.timeIntervalSince1970 - actualPositionStarted!.timeIntervalSince1970
            wrongPositionElapse = timeElapsed

            updateTimeRemaining(bmmStatus.startingTimeRemaining + 30 - timeElapsed) // Additional 30 seconds for offset with BMM
        } else {
            updateTimeRemaining(bmmStatus.startingTimeRemaining + 30)
        }

        if bmmMonitoringState == "onPause" {
            let actualPositionStarted = DateFormatter.regDateFormatter.date(from: bmmStatus.actualPositionStarted)
            updateTimer((actualPositionStarted ?? Date()).timeIntervalSince1970, bmmPauseReason)
            if let started = actualPositionStarted {
                cardData.pausedTime = Date().timeIntervalSince1970 - started.timeIntervalSince1970
            }
        } else {
            cardData.pausedTime = 0
        }
    }

    private func updateTurnDegreeInfoFrom(_ patientInfo: PatientInfo) {
        if let raw = patientInfo.turnProtocol, let turnProtocol = TurnProtocol(rawValue: raw) {
            self.turnProtocol = turnProtocol
            self.turningProtocol.turnProtocol = turnProtocol
        }

        if let deg = patientInfo.complianceDegree, let complianceAngle = ComplianceAngle(fromInt: deg) {
            self.complianceAngle = complianceAngle
            self.turningProtocol.complianceAngle = complianceAngle
        }
    }

    private func updatePatientFromPatientInfo(_ patientInfo: PatientInfo?) {
        guard let patientInfo = patientInfo else { return }
        patientDetailsViewModel?.heightInInches = patientInfo.heightInInches
        patientDetailsViewModel?.weightInPounds = patientInfo.weightInPounds
        patientDetailsViewModel?.sex = patientInfo.sexAtMeasurement.toALTSex()
        patientDetailsViewModel?.complianceDegree = patientInfo.complianceDegree
        patientDetailsViewModel?.turnProtocol = patientInfo.turnProtocol

        updateTurnDegreeInfoFrom(patientInfo)

        positionsToAvoid = []

        guard let props = patientInfo.props,
              !props.isEmpty,
              let propsJson = try? JSONDecoder().decode(Props.self, from: props.toData()) else {
            return
        }

        for char in propsJson.avoid {
            if char == "L" {
                positionsToAvoid.append(.left)
            } else if char == "R" {
                positionsToAvoid.append(.right)
            } else if char == "S" || char == "B" {
                positionsToAvoid.append(.supine)
            }
        }
    }

    private func updatePatientStateFromSession() {
        switch bmmMonitoringState {
        case "onStart":
            patientState = .noSession
        case "onResume":
            if patientState != .nonTargetPosition {
                patientState = .active
            }
            if isWrongPosition {
                startWrongPositionTimer()
            } else if !isWrongPosition {
                if patientState == .nonTargetPosition {
                    patientState = .active
                }
                resetWrongPositionTimer()
            }
        case "onPause":
            patientState = PatientState(pauseString: bmmPauseReason)
            stopWrongPositionTimer()
            if [
                "Swapping Sensor", "Swapping Patch", "Replacing Patch",
                "Sensor Disconnected", "End Session", "BMM Disconnected",
            ]
                .contains(bmmPauseReason) {
                currentWearable = nil
            }
            if ["Sensor Disconnected", "BMM Disconnected"]
                .contains(bmmPauseReason) {
                update(sensorState: .disconnected)
            }
            if bmmPauseReason == "End Session" {
                resetWrongPositionTimer()
                patientState = .noSession
            }
        default:
            break
        }
    }

    func updateAlertLevel() {
        switch patientState {
        case .active:
            if bmmState == .disconnected || cardData.sensorState == .disconnected || cardData.isLowBatteryCritical {
                currentAlert = .critical
            } else if cardData.isLowBatteryWarning {
                currentAlert = .warning
            } else {
                currentAlert = .green
            }
        case .noSession, .unassigned, .ready, .none:
            currentAlert = .none
        case .paused:
            currentAlert = .action
        case .overdue, .nonTargetPosition:
            currentAlert = .critical
        case .turnSoon:
            if bmmState == .disconnected || cardData.sensorState == .disconnected || cardData.isLowBatteryCritical {
                currentAlert = .critical
            } else {
                currentAlert = .warning
            }
        case .swappingPatch, .swappingSensor:
            currentAlert = .action
        }
    }
}

extension BMMViewModel {
	func updateBatteryLevel(_ newBatteryLevel: Int) {
        update(sensorState: newBatteryLevel <= 20 ? .lowBattery : .connected)
		
		guard currentWearable?.batteryPercentage != newBatteryLevel else { return }
		currentWearable?.batteryPercentage = newBatteryLevel
		alertSensorLowBattery()
		updateAlertLevel()
	}
}

// MARK: - Fetch Room and facility from DB
fileprivate extension BMMViewModel {
	func fetchAndUpdateRoomBed(id: String) {
		if let room = self.roomBedInfo, room.id == id {
            update(room: room.roomBedNumber)
		} else {
			roomBedInfo = HospitalRoomBed.getRoomBed(forId: id)
            update(room: roomBedInfo?.roomBedNumber)
		}
		
		if let unitId = self.roomBedInfo?.facilityUnitId {
			fetchUpdateUnit(id: unitId)
		}
	}
	
	func fetchUpdateUnit(id: String) {
		if let unit = self.facilityUnitInfo, unit.id == id {
			self.unit = unit.name
		} else {
			facilityUnitInfo = HospitalUnitInfo.getUnitInfo(forId: id)
			self.unit = facilityUnitInfo?.name
		}
	}
}
