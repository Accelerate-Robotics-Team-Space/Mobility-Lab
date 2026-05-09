//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import GRDB

protocol HospitalRoomBedRepositoryProtocol: DataStorableRepositoryProtocol where Record == HospitalRoomBed {
    func getRoomBed(forId id: String) -> HospitalRoomBed?
}

extension Container {
    var hospitalRoomBedRepository: Factory<any HospitalRoomBedRepositoryProtocol> {
        self { HospitalRoomBedRepository(resolve(\.databaseService)) }.cached
    }
}

final class HospitalRoomBedRepository: DataStorableRepository<HospitalRoomBed>, HospitalRoomBedRepositoryProtocol {
    func getRoomBed(forId id: String) -> HospitalRoomBed? {
        try? grdbService.reader.read { dataStore in
            try HospitalRoomBed.fetchOne(
                dataStore,
                sql: """
                     SELECT h.*
                     FROM hospitalRoomBed h
                     WHERE id = ?
                     """,
                arguments: [id]
            )
        }
    }
}
