//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import GRDB

protocol ConsoleLogRepositoryProtocol: DataStorableRepositoryProtocol where Record == ConsoleLogItem {
    func deleteOldItems(totalCount: Int)
}

extension Container {
    var consoleLogRepository: Factory<any ConsoleLogRepositoryProtocol> {
        self { ConsoleLogRepository(resolve(\.databaseService)) }.cached
    }
}

final class ConsoleLogRepository: DataStorableRepository<ConsoleLogItem>, ConsoleLogRepositoryProtocol {
    func deleteOldItems(totalCount: Int) {
        Task {
            do {
                try await grdbService.write { store in
                    try store.execute(
                        sql: """
                             DELETE FROM consoleLogItem
                             ORDER BY date DESC
                             LIMIT ? OFFSET 500
                             """,
                        arguments: [totalCount - 500]
                    )
                }
            } catch {
                logger.error(error.localizedDescription)
            }
        }
    }
}
