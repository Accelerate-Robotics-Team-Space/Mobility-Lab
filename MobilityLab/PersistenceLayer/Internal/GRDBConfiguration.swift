//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import GRDB

struct GRDBConfiguration {
    enum StorageLocation {
        case inMemory
        case onDisk(name: String)

        var databaseName: String {
            switch self {
            case .inMemory:         "ephemeral"
            case .onDisk(let name): name
            }
        }
    }

    var storageLocation: StorageLocation

    func makeGRDBConfiguration() -> Configuration {
        var configuration = Configuration()
        configuration.busyMode = .timeout(1.0)
        return configuration
    }
}
