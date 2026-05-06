//
//  UMMErrorLog.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 2/16/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB

struct UMMErrorLog: DataStorable {
    private(set) var id: Int64?
    private(set) var deviceUUID: String
    private(set) var dateCreated: Date
    private(set) var error: String
    private(set) var isSynced: Bool
    
    static let timeFormatter = DateComponentsFormatter()
    
    // MARK: - Init
    init(error: Error) {
        self.id = nil
        self.deviceUUID = UserDefaults.standard.unitMobilityMonitorGuid ?? "Unknown"
        self.dateCreated = Date()
        self.error = error.localizedDescription
        self.isSynced = false
    }
    
    // MARK: - Mutating
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    var stringRepresentation: String {
        return "[date:\(dateCreated)|error:\(error)|deviceID:\(deviceUUID)]"
    }

    static func stringForCrashReport() -> String {
        UMMErrorLog
            .loadAllFromDB()
            .sorted(by: { $0.dateCreated > $1.dateCreated })
            .map({ $0.stringRepresentation })
            .joined(separator: "\n")
    }
}

extension UMMErrorLog: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case deviceUUID
        case dateCreated
        case error
        case isSynced
    }
}
