//
//  DataFeedRequest.swift
//  SensorSuite
//
//  Created by Josh Franco on 9/8/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

struct DataFeedRequest: Serializable, Codable {
    static let previewRequest = DataFeedRequest()
    
    let wearableId: String
    let peripheralId: String
    
    // MARK: - Init
    private init() {
        self.wearableId = String.randAlphanumeric()
        self.peripheralId = ""
    }
    
    init(wearableId: String, peripheralId: String) {
        self.wearableId = wearableId
        self.peripheralId = peripheralId
    }
}
