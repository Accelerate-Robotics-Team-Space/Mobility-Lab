//
//  ScanDriver.swift
//  SensorSuite WatchKit Extension
//
//  Created by Josh Franco on 3/5/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import WatchKit

class ScanDriver: ObservableObject {
    @Published var showSessionFlow = false

    private var dismissTrigger: (() -> Void)?
    private(set) var connectionDriver: BLEConnectionDriver
    @Injected(\.workoutSession) private var workoutSession
    @Injected(\.locationService) var locationService
    var userDefaults: UserDefaults = .standard

    // MARK: - Init
    init(connectionDriver: BLEConnectionDriver) {
        self.connectionDriver = connectionDriver
    }
    
    deinit {
        logger.info("\(String(describing: self)) Deinitialization")
    }
    
    // MARK: - Util
    func startScan() {
        setupBleObservers()
        connectionDriver.scanForPeripherals()
    }

    func cancelScan() {
        connectionDriver.reset()
    }
    
    func dismissView(dismissTrigger: @escaping () -> Void) {
        self.dismissTrigger = dismissTrigger
    }
}

// MARK: - Private
private extension ScanDriver {
    func setupBleObservers() {
        connectionDriver.stateUpdated = { [weak self] state in
            if state == .idle {
                self?.dismissTrigger?()
                self?.workoutSession.stopWorkout()
                self?.locationService.stopLocationUpdate()
            } else if state == .active {
                if self?.connectionDriver.pairedPeripheral != nil {
                    self?.connectionDriver.declineUnpairedConnections()
                }
                self?.workoutSession.startWorkout()
                self?.locationService.startLocationUpdate()
            }
        }

        connectionDriver.valueUpdated = { [weak self] obj, peripheralId in
            switch obj {
            case .answerDataFeed(let answer):
                logger.debug("value answerDataFeed")
                self?.completeInitiationRequest(with: answer,
                                                for: peripheralId)
            case .rejectDataFeed(let request):
                logger.debug("value rejectDataFeed")
                self?.connectionDriver.declineConnection(wearableId: request.wearableId, peripheralId: peripheralId)
            case .requestCalibrationPoint:
                logger.debug("value requestCalibrationPoint")
                self?.connectionDriver.sendCalibrationPoint()
            // Other cases are part of the active session flow and shuold not be handled here
            default: break
            }
        }
    }
    
    func completeInitiationRequest(with answer: DataFeedInitAnswer, for confirmedId: UUID) {
        guard answer.isCoupled else { return }
        
        userDefaults.facilityName = answer.facilityName
        connectionDriver.confirmConnection(id: confirmedId, wearableLocation: answer.wearableLocation)

        dismissTrigger?()
        showSessionFlow = true
    }
}
