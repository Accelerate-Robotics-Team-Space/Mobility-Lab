//
//  TurnTrackerInfo.swift
//  SensorSuite
//
//  Created by Josh Franco on 12/16/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

protocol TurnTrackerDelegate: AnyObject {
    func getPositionSequence() -> [PositionalFlagCategory]
}

class TurnTrackerInfo {
    var endDate: Date?

    private(set) var isTracking = false
    private(set) var remainingTime: TimeInterval?
    private(set) var currentTurningProto: TurningProtocol?
    
    weak var delegate: TurnTrackerDelegate?
    
    // MARK: - Computed Variables
    var sequence: [PositionalFlagCategory] {
        let seq = delegate?.getPositionSequence() ?? []
        if Set(orderedSequence) != Set(seq) {
            applyChange(of: seq)
        }
        return orderedSequence
    }
    
    private var orderedSequence: [PositionalFlagCategory] = []

    // MARK: - Enum
    enum PositionOrder {
        case current
        case next
    }
	
	init() { }
	
	init(
		endDate: Date?,
		positionalFlagCategory: PositionalFlagCategory,
		remainingTime: TimeInterval,
		delegate: TurnTrackerDelegate?
	) {
		self.delegate = delegate
        self.orderedSequence = delegate?.getPositionSequence() ?? []
        apply(target: positionalFlagCategory)
        self.remainingTime = remainingTime
        self.endDate = endDate
	}
    
    // MARK: - Util
    func reset() {
        endDate = nil
        remainingTime = nil
    }
    
    func toggleTracking(to tracking: Bool? = nil) {
        if let tracking {
            isTracking = tracking
        } else {
            isTracking.toggle()
        }
    }
    
    func updateRemainingTime(to remainingTime: TimeInterval? = nil) {
        if let remainingTime {
            self.remainingTime = remainingTime
            return
        }

        guard let endDate = endDate else { return }
        
        let nowReference = Date().timeIntervalSinceReferenceDate
        let endReference = endDate.timeIntervalSinceReferenceDate
        
        self.remainingTime = endReference - nowReference
    }
    
    func updateTrackerProtocol(_ toProtocol: TurningProtocol) {
        guard currentTurningProto != toProtocol else { return }
        
        currentTurningProto = toProtocol
        isTracking = false
        remainingTime = nil
        endDate = nil
    }
    
    // MARK: - Pos Sequence
    func updateToNextPos() {
        guard !orderedSequence.isEmpty else { return }
        orderedSequence.append(orderedSequence.removeFirst())
    }
    
    func getPositionOrder(_ order: PositionOrder) -> PositionalFlagCategory {
        guard !sequence.isEmpty else {
			return .other
		}
        
        switch order {
        case .current:
            return sequence[0]
        case .next:
            return sequence[1]
        }
    }

    private func applyChange(of seq: [PositionalFlagCategory]) {
        let target = orderedSequence.first
        orderedSequence = seq
        if let target {
            apply(target: target)
        }
    }

    func apply(target: PositionalFlagCategory) {
        var index = orderedSequence.firstIndex(of: target)
        guard orderedSequence.contains(target) else {
            return
        }
        while index != 0 {
            updateToNextPos()
            index = orderedSequence.firstIndex(of: target)
        }
    }
}
