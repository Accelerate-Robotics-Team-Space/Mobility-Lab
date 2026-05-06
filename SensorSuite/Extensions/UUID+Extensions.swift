//
//  UUID+Extensions.swift
//  SensorSuite
//
//  Created by Josh Franco on 1/28/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import Foundation

extension UUID {
    var formatted: String {
        let splitUUID = self.uuidString.split(separator: "-")
        let nodeGroup = String(splitUUID[splitUUID.endIndex - 1])
        
        return String(nodeGroup.prefix(5))
    }

    static let null = UUID(uuid: UUID_NULL)
}
