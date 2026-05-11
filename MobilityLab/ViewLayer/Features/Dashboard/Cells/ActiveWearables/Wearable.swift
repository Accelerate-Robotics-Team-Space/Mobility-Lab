//
//  Wearable.swift
//  MobilityLab
//
//  Created by Josh Franco on 12/21/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

class Wearable: Identifiable {
    static let devWearable = Wearable()
    static let previewWearables = [
        Wearable(),
        Wearable(),
        Wearable(),
    ]

    let id: String
    let guuid: UUID
    let bleCentralId: UUID
    let version: String
    let location: WearableLocation
    var batteryLvl: Int
    var previousBatteryLvl: Int?
    var batteryTimeRemaining: Int
    var calibrationPoint: DataPoint?
    var patch: WearablePatch
    var start: Date?
    
    init(
        id: String,
        guuid: UUID,
        bleId: UUID,
        version: String,
        location: WearableLocation,
        batterylvl: Int = 0,
        batteryTimeRemaining: Int = -1
    ) {
        self.id = id
        self.guuid = guuid
        self.bleCentralId = bleId
        self.version = version
        self.location = location
        self.batteryLvl = batterylvl
        self.batteryTimeRemaining = batteryTimeRemaining
        self.patch = WearablePatch(currentLocation: location)
    }
    
    private init() {
        self.id = "SOMERANDID"
        self.guuid = UUID(uuidString: "AAAAAAAA-1111-2222-3333-BBBBBBBBBBBB") ?? UUID()
        self.bleCentralId = UUID()
        self.location = .chest
        self.batteryLvl = Int.random(in: 0...100)
        self.batteryTimeRemaining = Int.random(in: 0...100)
        self.version = "0.0.1"
        self.patch = WearablePatch(currentLocation: .chest)
    }
}

extension Wearable: Hashable {
    static func == (lhs: Wearable, rhs: Wearable) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id.hashValue)
    }
}
