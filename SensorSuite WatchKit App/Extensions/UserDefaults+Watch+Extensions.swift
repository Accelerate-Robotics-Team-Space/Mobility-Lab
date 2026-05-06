//
//  UserDefaults+Watch+Extensions.swift
//  SensorSuite
//
//  Created by Josh Franco on 9/1/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation
import WatchKit

extension UserDefaults {
    private enum Keys: String {
        case wearableGuid = "Wearable-Globally-Unique-Identifier"
        case wearableId = "Wearable-Identifier"
        case facilityName = "Facility-Name"
    }
    
    var wearableGuid: UUID? {
        get {
            guard let guidStr = string(forKey: Keys.wearableGuid.rawValue) else {
                return WKInterfaceDevice.current().identifierForVendor
            }
            return UUID(uuidString: guidStr)
        } 
        set { set(newValue?.uuidString, forKey: Keys.wearableGuid.rawValue) }
    }
    
    var wearableId: String {
        get {
            let key = Keys.wearableId.rawValue
            
            if let identifier = string(forKey: key) {
                return identifier
            } else {
                let newID = String.randAlphanumeric()
                UserDefaults.standard.set(newID, forKey: key)
                return newID
            }
        } 
        set { set(newValue, forKey: Keys.wearableId.rawValue) }
    }
    
    var facilityName: String? {
        get { string(forKey: Keys.facilityName.rawValue) }
        set { set(newValue, forKey: Keys.facilityName.rawValue) }
    }
}
