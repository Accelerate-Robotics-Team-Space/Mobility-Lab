//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
import GRDB

struct ConsoleLogItem: DataStorable, Codable, Hashable {
    private(set) var id: Int64?
    private(set) var message: String
    private(set) var date: Date

    var stringRepresentation: String {
        return "[\(date)]: [\(message)]"
    }
}
