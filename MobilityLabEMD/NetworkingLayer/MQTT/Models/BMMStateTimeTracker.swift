//
//  BMMStateTimeTracker.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 8/8/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol BMMStateTimeTrackerProtocol {
    func startWrongPosition(completion: @escaping () -> Void)
    func stopWrongPosition()
    func resetWrongPosition()

    func startTurn(completion: @escaping () -> Void)
    func stopTurn()

    func startSwapping(completion: @escaping () -> Void)
    func stopSwapping()

    func startDisconnected(completion: @escaping () -> Void)
    func stopDisconnected()

    func startIsAlive(completion: @escaping () -> Void)
    func stopIsAlive()
}

extension Container {
    var bmmStateTimeTracker: Factory<BMMStateTimeTrackerProtocol> {
        self { BMMStateTimeTracker() }
    }
}

class BMMStateTimeTracker: BMMStateTimeTrackerProtocol {
    private var turnTimer: Timer?
    private var wrongPositionTimer: Timer?
    private var swappingTimer: Timer?
    private var sensorDisconnectedTimer: Timer?
    private var isAliveTimer: Timer?

    func startWrongPosition(completion: @escaping () -> Void) {
        if wrongPositionTimer == nil {
            wrongPositionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                completion()
            }
        }
    }

    func stopWrongPosition() {
        wrongPositionTimer?.invalidate()
        wrongPositionTimer = nil
    }

    func resetWrongPosition() {
        stopWrongPosition()
    }

    func startTurn(completion: @escaping () -> Void) {
        stopTurn()
        turnTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            completion()
        }
    }

    func stopTurn() {
        turnTimer?.invalidate()
        turnTimer = nil
    }

    func startSwapping(completion: @escaping () -> Void) {
        stopSwapping()
        swappingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            completion()
        }
    }

    func stopSwapping() {
        swappingTimer?.invalidate()
        swappingTimer = nil
    }

    func startDisconnected(completion: @escaping () -> Void) {
        stopDisconnected()
        sensorDisconnectedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            completion()
        }
    }

    func stopDisconnected() {
        sensorDisconnectedTimer?.invalidate()
        sensorDisconnectedTimer = nil
    }

    func startIsAlive(completion: @escaping () -> Void) {
        if isAliveTimer == nil {
            isAliveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                completion()
            }
        }
    }

    func stopIsAlive() {
        isAliveTimer?.invalidate()
        isAliveTimer = nil
    }
}
