//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import GRDB

class Migration {
    var identifier: String {
        let identifier = String(describing: Self.self)
        assert(identifier != String(describing: Migration.self), "`Migration` must be subclassed")
        return identifier
    }

    required init() { }

    func perform(on database: Database) throws {
        fatalError("You must override `perform(on:) to implement your migration")
    }
}
