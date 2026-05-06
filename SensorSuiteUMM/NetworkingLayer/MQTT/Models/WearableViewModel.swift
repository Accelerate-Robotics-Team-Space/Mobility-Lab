//
//  WearableViewModel.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/31/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

class WearableViewModel: ObservableObject {
    @Published var id: String
    @Published var wearbleLocated: WearableLocation?
    @Published var batteryPercentage: Int?
    @Published var previousBatteryPercentage: Int?
    @Published var start: Date?
    @Published var wearableState: WearableState?
    @Published var wearableSerialNum: String?
    @Published var alive: Bool = false
    
    enum WearableLocation: String {
        case chest = "Chest"
        case leftHand = "Left Hand"
        case rightHand = "Right Hand"
        case leftLeg = "Left Leg"
        case rightLeg = "Right Leg"
    }

    enum WearableState: String {
        case monitoring = "Monitoring"
        case paused = "Paused"
        case disconnected = "Disconnected"
    }
    
    init(id: String,
         wearbleLocated: WearableLocation? = .chest,
         batteryPercentage: Int? = nil,
         wearableState: WearableState? = nil,
         wearableSerialNum: String? = nil
    ) {
        self.id = id
        self.wearbleLocated = wearbleLocated
        self.batteryPercentage = batteryPercentage
        self.wearableState = wearableState
        self.wearableSerialNum = wearableSerialNum
    }
}
