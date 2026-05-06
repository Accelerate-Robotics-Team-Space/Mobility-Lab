//
//  DataPointAnalyzer.swift
//  SensorSuite
//
//  Created by Josh Franco on 3/10/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol DataPointAnalyzerDelegate: AnyObject {
    func perceivedActualPositionUpdated(_ position: PositionalFlagCategory)
}

final class DataPointAnalyzer {
    weak var delegate: DataPointAnalyzerDelegate?
    
    private let bufferSize = 5
    private let analyzerQueue = DispatchQueue(label: "Data_Point_Analyzer", qos: .userInteractive)
    
    private var flagBuffer: [PositionalFlags] = []
    private var classifier: ChestMonitorClassifier = .init(complianceAngle: .angle20)
    @Injected(\.userDefaults) private var userDefaults

    // MARK: - Init
    init() {}
    
    // MARK: - Util
    func analyze(_ point: DataPoint) {
        analyzerQueue.async {
            self.updateBuffer(with: point)
        }
    }
}

// MARK: - Private
private extension DataPointAnalyzer {
    func updateBuffer(with point: DataPoint) {
        if let currentComplianceAngle = userDefaults.complianceAngle,
           classifier.complianceAngle != currentComplianceAngle {
            self.classifier = .init(complianceAngle: currentComplianceAngle)
        }
        let newFlag = classifier.position(from: point)
        flagBuffer.append(newFlag)
        
        if flagBuffer.count >= bufferSize {
            let bufferDelta = flagBuffer.count - bufferSize
            flagBuffer.removeFirst(bufferDelta)
        }
        
        var occurrenceDict: [UInt32: Int] = [:]
        flagBuffer.forEach { occurrenceDict[$0.rawValue] = (occurrenceDict[$0.rawValue] ?? 0) + 1 }
        
        let maxFlag = PositionalFlags(rawValue: occurrenceDict.keys.max() ?? 0)
        delegate?.perceivedActualPositionUpdated(.init(using: maxFlag))
    }
}
