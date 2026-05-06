//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import GRDB

struct BMMErrorLog: DataStorable, Hashable {
    private(set) var id: Int64?
    private(set) var deviceUUID: String
    private(set) var dateCreated: Date
    private(set) var error: String
    private(set) var isSynced: Bool
    
    static let timeFormatter = DateComponentsFormatter()
    
    // MARK: - Init
    init(error: Error, deviceUUID: String, id: Int64? = nil, date: Date = .now) {
        self.id = id
        self.deviceUUID = deviceUUID
        self.dateCreated = date
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

    static func stringForCrashReport(container: Container = .shared) -> String {
        let errorLogRepository = container.errorLogRepository.resolve()
        let logs: [BMMErrorLog] = errorLogRepository.syncLoadAllFromDB()
        return logs.sorted(by: { $0.dateCreated > $1.dateCreated })
            .map({ $0.stringRepresentation })
            .joined(separator: "\n")
    }
}

extension BMMErrorLog: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case deviceUUID
        case dateCreated
        case error
        case isSynced
    }
}
