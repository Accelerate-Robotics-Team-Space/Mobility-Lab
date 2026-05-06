//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import GRDB

protocol ErrorLogRepositoryProtocol: DataStorableRepositoryProtocol where Record == BMMErrorLog { }

extension Container {
    var errorLogRepository: Factory<any ErrorLogRepositoryProtocol> {
        self { ErrorLogRepository(resolve(\.databaseService)) }.cached
    }
}

final class ErrorLogRepository: DataStorableRepository<BMMErrorLog>, ErrorLogRepositoryProtocol { }
