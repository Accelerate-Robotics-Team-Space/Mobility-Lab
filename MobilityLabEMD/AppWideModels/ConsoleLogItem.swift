//
//  ConsoleLogItem.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 2/12/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB

struct ConsoleLogItem: DataStorable, Codable {
    private(set) var id: Int64?
    private(set) var message: String
    private(set) var date: Date

    var stringRepresentation: String {
        return "[\(date)]: [\(message)]"
    }

    static func deleteOldItems(totalCount: Int) {
        do {
            try DataStore.shared.writer?.write { store in
                try store.execute(sql: """
                    DELETE FROM consoleLogItem
                    ORDER BY date DESC
                    LIMIT ? OFFSET 500
                """, arguments: [totalCount - 500])
            }
        } catch {
            logger.error(error.localizedDescription)
        }
    }
}
