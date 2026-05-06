//
//  SessionDriver.swift
//  SensorSuite WatchKit Extension
//
//  Created by Josh Franco on 11/2/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import WatchKit

class SessionDriver: ObservableObject {
    @Published var isSensing = false {
        didSet {
            broadcastIfNeeded()
        }
    }
    @Published var endSession: Bool

    private let connectionDriver: BLEConnectionDriver?
    @Injected(\.notificationCenter) private var notificationCenter
    private var lastBatteryLvl = 0
    private var lastBroadcast = Date.distantPast
    private var timer = Timer()
    private let currentDevice = WKInterfaceDevice.current()

    // TODO: Inject with FactoryKit when available
    private let deviceMotionManager: DeviceMotionManagerProtocol = DeviceMotionManager.shared
    @Injected(\.workoutSession) private var workoutSession
    @Injected(\.locationService) private var locationService
    private let userDefaults: UserDefaults = .standard

    // MARK: - Init
    init(connectionDriver: BLEConnectionDriver?) {
        self.connectionDriver = connectionDriver
        self.endSession = false
        deviceMotionManager.initaliseDatasources()

        connectionDriver?.transmitter?.updateBuffer(with: 1)
        checkBatteryLife()
    
        currentDevice.isBatteryMonitoringEnabled = true
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkBatteryState), userInfo: nil, repeats: true)
    }
    
    init() {
        self.connectionDriver = nil
        self.endSession = false
    }
    
    // MARK: - Util
    func tearDown() {
        logger.debug("teardown")
        connectionDriver?.reset()
        timer.invalidate()
        endSession = true
        workoutSession.stopWorkout()
        locationService.stopLocationUpdate()
    }
    
    func onAppear() {
        setupBleObservers()
        notificationCenter.addObserver(self, selector: #selector(sendData), name: DeviceMotionManager.newDataNote, object: nil)
    }
    
    func getBuildInfoStr() -> String {
        if ALTEnvironment.current != .prod {
            let versionNum = R.string.localizable.versionNum(WatchConstants.versionNumStr)
            let env = ALTEnvironment.current.abbreviation
            
            return """
                    \(versionNum) \(WatchConstants.buildNumStr) | \(env)
                    \(userDefaults.facilityName ?? "Unknown")
                    """
        } else {
            let versionNum = R.string.localizable.versionNum(WatchConstants.versionNumStr)
            
            return "\(versionNum)"
        }
    }
    
    @objc
    func checkBatteryState() {
        if currentDevice.batteryState.rawValue == 2 || currentDevice.batteryState.rawValue == 3 {
            connectionDriver?.transmitter?.queueChar(.dismissBatteryLow(request: JustRequest()))
        }
    }
}

// MARK: - Private
private extension SessionDriver {
    func broadcastIfNeeded() {
        connectionDriver?.transmitter?.queueChar(.trackingUpdated(isTracking: isSensing))
        lastBroadcast = Date()
    }
    
    func setupBleObservers() {
        connectionDriver?.valueUpdated = { [weak self] value, peripheralId in
            guard let self = self else { return }
            
            switch value {
            case .answerDataFeed(let answer):
                logger.debug("value answerDataFeed")
                self.completeInitiationRequest(with: answer,
                                               for: peripheralId)
            case .trackingUpdated(let isTracking):
                guard isTracking != self.isSensing else { break }
                self.isSensing = isTracking
            case .requestCalibrationPoint:
                self.connectionDriver?.sendCalibrationPoint()
            case .requestTerminate:
                self.notificationCenter.removeObserver(
                    self,
                    name: DeviceMotionManager.newDataNote,
                    object: nil
                )
                let confirm = TerminateConfirmation(success: true)
                self.connectionDriver?.transmitter?.queueChar(.terminateAnswer(answer: confirm))
                self.tearDown()
            case .rejectDataFeed(let request):
                if connectionDriver?.pairedPeripheral?.identifier == peripheralId,
                    request.wearableId != userDefaults.wearableId {
                    return
                }
                self.notificationCenter.removeObserver(
                    self,
                    name: DeviceMotionManager.newDataNote,
                    object: nil
                )
                let confirm = TerminateConfirmation(success: true)
                self.connectionDriver?.transmitter?.queueChar(.terminateAnswer(answer: confirm))
                self.tearDown()
            // Other cases are part of the scanning/pairing flow and should not be handled here
            default: break
            }
        }
        
        connectionDriver?.stateUpdated = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .idle:
                self.tearDown()
                logger.debug("connectionDriver state updated to idle")
            case .active:
                self.connectionDriver?.transmitter?
                    .queueChar(.batteryLvl(data: BatteryLevelData(
                        batteryLvl: UInt8(WatchConstants.watchBatteryPercentage),
                        wearableId: userDefaults.wearableId))
                    )
                workoutSession.startWorkout()
                locationService.startLocationUpdate()
            default: break
            }
        }
    }
    
    func checkBatteryLife() {
        let newBatteryLvl = WatchConstants.watchBatteryPercentage
        if newBatteryLvl != lastBatteryLvl {

            lastBatteryLvl = newBatteryLvl
            let batteryData = BatteryLevelData(
                batteryLvl: UInt8(newBatteryLvl),
                wearableId: userDefaults.wearableId
            )
            connectionDriver?.transmitter?.queueChar(.batteryLvl(data: batteryData))
        }
    }
    
    @objc
    func sendData(notification: NSNotification) {
        guard
            let data = notification.userInfo as? [String: DataPoint],
            let dataPoint = data["data"] else {
                logger.warn("Could not cast userInfo from notification")
                return
            }
        
        connectionDriver?.transmitter?.queueChar(.dataFeed(dataPoint: dataPoint))
        checkBatteryLife()
    }

    func completeInitiationRequest(with answer: DataFeedInitAnswer, for confirmedId: UUID) {
        guard answer.isCoupled else { return }

        userDefaults.facilityName = answer.facilityName
        connectionDriver?.confirmConnection(id: confirmedId, wearableLocation: answer.wearableLocation)
    }
}
