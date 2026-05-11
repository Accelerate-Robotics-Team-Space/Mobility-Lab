//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import GRDB

protocol RevokedCertificateRepositoryProtocol: DataStorableRepositoryProtocol where Record == RevokedCertificate { }

extension Container {
    var revokedCertificateRepository: Factory<any RevokedCertificateRepositoryProtocol> {
        self { RevokedCertificateRepository(resolve(\.databaseService)) }.cached
    }
}

final class RevokedCertificateRepository: DataStorableRepository<RevokedCertificate>, RevokedCertificateRepositoryProtocol { }
