//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//

import Foundation

/// SessionWearableDelegate for PatientMonitorDriver.swift
protocol PatientMonitorDriverWearableDelegate: AnyObject {
    /// Triggers when a wearable's patch has expired
    func wearablePatchExpired()
    func dismissBatteryLow()
    func resumeMonitor()
    func userDidSelectPairing()
}

protocol PatientMonitorDriverLocationDelegate: AnyObject {
    func locationUpdated(hospitalRoomBedId: String)
}

// MARK: - SessionPositionDelegate
extension PatientMonitorDriver: SessionPositionDelegate {
    func actualPerceivedPositionUpdated(_ pos: PositionalFlagCategory) {
        DispatchQueue.main.async { [weak self] in
            self?.updateActualPosition(to: pos)
        }
    }

    func isWearableConnected(_ isConnected: Bool) {
        isWearableConnected = isConnected
        if currentState != .onStart {
            if isWearableConnected {
                displayRePairSensorAlert = false
                if shouldAutoResume {
                    setTrackingTo(to: true)
                    shouldAutoResume = false
                    if let resumeSession {
                        apply(resumeSession: resumeSession)
                        updateLogEndTargetAndSend()
                        createNewLog()
                    }
                } else {
                    setTrackingTo(to: currentState == .onPause ? false : true)
                }
            } else {
                if pauseReason != .swappingPatch && pauseReason != .swappingWearable {
                    pauseReason = .disconnected
                }
                setTrackingTo(to: false)
                if startNextPositionConfirmation {
                    startNextPositionConfirmation = false
                }
            }
            updateTracking()
        }
    }

    func wearableTrackingUpdated(_ isTracking: Bool) {
        guard self.isTracking != isTracking else { return }

        info?.toggleTracking(to: isTracking)
        updateTracking()
    }

    func monitoringState() -> PatientMonitorState {
        currentState
    }
}

// MARK: - SessionWearableDataPointDelegate
extension PatientMonitorDriver: SessionWearableDataPointDelegate {
    func batteryLvlChanged(from bleId: UUID, _ newBatteryLevel: Int) {
        guard case .connected(let id, _) = patientManager.session?.blePeripheral.state,
              id == bleId else {
            return
        }
        sensorBatteryPercentage = newBatteryLevel
    }

    func dataFeedUpdate(_ feedResult: DataPointResult) {
        switch feedResult {
        case .dataPointResult(let point):
            // Using first active wearable's calibration point
            if !patientManager.wearables.isEmpty {
                guard let calibrationPoint = patientManager.wearables.first?.calibrationPoint else {
                    let rollAngle = point.rollAttitude * 180 / Double.pi
                    let pitchAngle = processRadiansToDegrees(point.pitchAttitude, zGravity: point.zGravity)
                    DispatchQueue.main.async { [weak self] in
                        self?.rollDegree = rollAngle
                        self?.pitchDegree = pitchAngle
                    }
                    return
                }

                let calibratedRoll = point.rollAttitude - calibrationPoint.rollAttitude
                let calibratedPitch = point.pitchAttitude - calibrationPoint.pitchAttitude

                let rollAngle = calibratedRoll * 180 / Double.pi
                let pitchCorrected = processRadiansToDegrees(calibratedPitch, zGravity: point.zGravity)

                DispatchQueue.main.async { [weak self] in
                    self?.rollDegree = rollAngle
                    self?.pitchDegree = pitchCorrected
                }
            }
        }
    }

    private func angleCorrection(_ rawAngleRadians: Double, zGravity: Double) -> Double {
        // if patient is inverted, subtract appropriate amount. otherwise leave as-is
        let pitchOffsetRadians = zGravity < 0 ? 0 : (rawAngleRadians * 2 + .pi)
        return rawAngleRadians - pitchOffsetRadians
    }

    private func radiansToDegrees(_ radians: Double) -> Double {
        radians * 180 / .pi
    }

    private func processRadiansToDegrees(_ rawAngleRadians: Double, zGravity: Double) -> Double {
        radiansToDegrees(angleCorrection(rawAngleRadians, zGravity: zGravity))
    }
}

// MARK: - PatientMonitorDriverWearableDelegate
extension PatientMonitorDriver: PatientMonitorDriverWearableDelegate {
    func wearablePatchExpired() {
        displayPatchExpiredAlert = true
    }

    func dismissBatteryLow() {
        lowBattery = false
        if alertQueue.contains(.sensorLowBattery) {
            alertQueue.removeAll(where: { $0 == .sensorLowBattery })
        }
    }

    func userDidSelectPairing() {
        userSelectedPairing = true
        if currentState == .onPause && canInsert && (pauseReason != .swappingPatch && pauseReason != .swappingWearable) {
            setTrackingTo(to: true)
        }
    }

    func resumeMonitor() {
        displayRePairSensorAlert = false
        if currentState == .onPause && canInsert && (pauseReason != .swappingPatch && pauseReason != .swappingWearable) && userSelectedPairing {
            currentState = .onResume
        }
    }
}

// MARK: - PatientMonitorDriverLocationDelegate
extension PatientMonitorDriver: PatientMonitorDriverLocationDelegate {
    func locationUpdated(hospitalRoomBedId: String) {
        guard !patientManager.wearables.isEmpty,
              let turnProtocol = userDefaults.turnProtocol,
              let currentSession = patientManager.session?.currentSession,
              isWearableConnected else {
            return
        }

        displayRePairSensorAlert = false
        let topic = DataFeedTopics.sessionObservation(
            facilityID: userDefaults.facilityId,
            baseStationGuid: userDefaults.baseStationGuid,
            wearableGuuid: patientManager.wearables[0].guuid
        )
        updateLogEndTargetAndSend()
        startUpdateTimer()
        let log = ALTActivityLog(
            session: currentSession,
            actualPosition: actualPosition,
            startingTarget: desiredPosition,
            startingTimeRemaining: timeRemaining ?? turnProtocol.duration,
            bmmMonitoringState: currentState.rawValue,
            bmmPauseReason: pauseReason.rawValue,
            isWrongPosition: !actualPosition.isCompliance(with: desiredPosition),
            hospitalRoomBedId: hospitalRoomBedId,
            mqttTopicStr: topic.structure,
            updateId: UUID().uuidString,
            headOfBedAngle: headOfBedAngle,
            turnAngle: turnAngle,
            endingTargetPosition: nextDesiredPosition.encoded
        )
        set(activityLog: log)
        publishLog()
    }
}

// MARK: - Position To Avoid Updated Delegate
extension PatientMonitorDriver: PositionToAvoidUpdatedDelegate {
    func positionToAvoidUpdated() {
        guard currentState != .onStart else {
            if patientManager.posToAvoid.contains(desiredPosition) {
                info?.updateToNextPos()
                desiredPosition = info?.getPositionOrder(.current) ?? .other
            }
            nextDesiredPosition = info?.getPositionOrder(.next) ?? .other
            return
        }

        guard !patientManager.posToAvoid.contains(desiredPosition) else {
            moveToNextPosition()
            return
        }

        nextDesiredPosition = patientManager.turnTrackerInfo?.getPositionOrder(.next) ?? .other
    }
}
