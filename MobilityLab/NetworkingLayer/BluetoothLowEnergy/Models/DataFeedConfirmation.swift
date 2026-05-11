//
//  CouplingConfirmation.swift
//  MobilityLab
//
//  Created by Josh Franco on 9/8/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

struct DataFeedConfirmation: Serializable, Codable {
    let wearableId: String?
    let wearableGuuid: UUID?
    let location: WearableLocation
    let version: String
    
    // MARK: Computed Varables
    var isConfirmed: Bool {
        wearableId != nil && wearableGuuid != nil
    }
    
    // MARK: - Init
    init(wearableId: String?, wearableGuuid: UUID?, location: WearableLocation, version: String) {
        self.wearableId = wearableId
        self.wearableGuuid = wearableGuuid
        self.location = location
        self.version = version
    }
}
