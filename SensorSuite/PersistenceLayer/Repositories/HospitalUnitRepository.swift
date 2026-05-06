//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
import GRDB

protocol HospitalUnitRepositoryProtocol: DataStorableRepositoryProtocol where Record == HospitalUnit {
    func getAll() async -> [HospitalUnitInfo]

    @discardableResult func update(
        newUnits: [HospitalUnit],
        newRoomBeds: [HospitalRoomBed],
        existing: [HospitalUnitInfo],
        roomBedRepository: (any HospitalRoomBedRepositoryProtocol)?
    ) -> (units: Diffs<HospitalUnit>, rooms: Diffs<HospitalRoomBed>)

    @discardableResult func update(
        newUnits: [HospitalUnit],
        newRoomBeds: [HospitalRoomBed],
        existing: [HospitalUnitInfo]
    ) -> (units: Diffs<HospitalUnit>, rooms: Diffs<HospitalRoomBed>)
}

extension Container {
    var hospitalUnitRepository: Factory<any HospitalUnitRepositoryProtocol> {
        self { HospitalUnitRepository(resolve(\.databaseService)) }.cached
    }
}

final class HospitalUnitRepository: DataStorableRepository<HospitalUnit>, HospitalUnitRepositoryProtocol {
    func getAll() async -> [HospitalUnitInfo] {
        do {
            return try await grdbService.read { store in
                let request = HospitalUnit.including(all: HospitalUnit.rooms)
                return try HospitalUnitInfo.fetchAll(store, request)
            }
        } catch {
            logger.error(error.localizedDescription)
            return []
        }
    }

    @discardableResult
    func update(
        newUnits: [HospitalUnit],
        newRoomBeds: [HospitalRoomBed],
        existing: [HospitalUnitInfo],
        roomBedRepository: (any HospitalRoomBedRepositoryProtocol)? = nil
    ) -> (units: Diffs<HospitalUnit>, rooms: Diffs<HospitalRoomBed>) {
        let dbUnits: [HospitalUnit] = existing.map { HospitalUnit(using: $0) }
        let diffUnits: Diffs<HospitalUnit> = newUnits.diffWith(existing: dbUnits)
        for insertedUnit in diffUnits.newAndUpdated {
            syncSaveToDB(insertedUnit)
        }
        for deletedUnit in diffUnits.removed {
            deleteFromDB(deletedUnit)
        }

        let roomBedRepository = roomBedRepository ?? Container.shared.hospitalRoomBedRepository.resolve()

        let unitIDs = Set(diffUnits.retained.map(\.id))
        let dbRoomBeds: [HospitalRoomBed] = existing.flatMap { $0.roomBeds }
        let filteredRoomBeds: [HospitalRoomBed] = newRoomBeds.filter { unitIDs.contains($0.facilityUnitId) }
        let diffRoomBeds: Diffs<HospitalRoomBed> = filteredRoomBeds.diffWith(existing: dbRoomBeds)
        for insertedRoomBed in diffRoomBeds.newAndUpdated {
            roomBedRepository.syncSaveToDB(insertedRoomBed)
        }
        for deletedRoomBed in diffRoomBeds.removed {
            roomBedRepository.deleteFromDB(deletedRoomBed)
        }
        return (units: diffUnits, rooms: diffRoomBeds)
    }
}

extension HospitalUnitRepositoryProtocol {
    @discardableResult
    func update(
        newUnits: [HospitalUnit],
        newRoomBeds: [HospitalRoomBed],
        existing: [HospitalUnitInfo]
    ) -> (units: Diffs<HospitalUnit>, rooms: Diffs<HospitalRoomBed>) {
        update(
            newUnits: newUnits,
            newRoomBeds: newRoomBeds,
            existing: existing,
            roomBedRepository: nil
        )
    }
}
