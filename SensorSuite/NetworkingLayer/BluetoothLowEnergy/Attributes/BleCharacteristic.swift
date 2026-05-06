//
//  BleCharacteristic.swift
//  SensorSuite
//
//  Created by Josh Franco on 8/25/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import Foundation

enum BleCharacteristic: String {
    case dataFeed = "A0116C44-9D62-4E10-9B09-AAFB8DBF414C"
    case calibrationPoint = "E4C1B136-F85B-40B9-BC36-9852785E3C96"
    case requestDataFeed = "81776521-1A77-43A4-92A9-05F15F8C56C7"
    case requestCalibrationPoint = "9AD603EF-D645-4BB9-96A1-5337B69B1C16"
    case answerDataFeed = "48E56A77-35EF-428B-BE31-EC8CEEEB0306"
    case rejectDataFeed = "CD4C91BA-1A9D-4AB7-AECC-EBAC80CE3BE4"
    case confirmDataFeed = "A21C52DA-22C6-43C8-ADDA-FB7FF51B289C"
    case dataFeedStatus = "38D9D922-1525-48E6-BDF9-58CBF0297CDB"
    case requestWatchProvisioning = "07A22593-33A0-4942-9D8F-1D9D7E2CA85E"
    case fulfillWatchProvisioning = "EF6521E0-16E4-4025-A48D-8DE9679B47A8"
    case confirmWatchProvisioning = "6E8A32A5-87E3-4594-B2EE-9C091B3E5F28"
    case batteryLvl = "51D381FD-A323-4C20-8264-ABEEF2C7FFE5"
    case revokeWatchCert = "9528A6C6-9D27-444B-9486-99036C9E7084"
    case requestTerminate = "F4711B0E-43B3-4264-8FC6-FD713683A7AA"
    case terminateAnswer = "25F8E6EF-CCB2-4007-A3A8-8C115E0905C9"
    case dismissBatteryLow = "18F17D48-BE60-4C22-AC83-77065CCA5EDA"
    
    var uuid: CBUUID {
        CBUUID(string: self.rawValue)
    }
    
    init?(using id: CBUUID) {
        guard let newChar = BleCharacteristic(rawValue: id.uuidString) else { return nil }
        
        self = newChar
    }

    var stringDescription: String {
        switch self {
        case .dataFeed:
            return "dataFeed"
        case .calibrationPoint:
            return "calibrationPoint"
        case .requestDataFeed:
            return "requestDataFeed"
        case .requestCalibrationPoint:
            return "requestCalibrationPoint"
        case .answerDataFeed:
            return "answerDataFeed"
        case .rejectDataFeed:
            return "rejectDataFeed"
        case .confirmDataFeed:
            return "confirmDataFeed"
        case .dataFeedStatus:
            return "dataFeedStatus"
        case .requestWatchProvisioning:
            return "requestWatchProvisioning"
        case .fulfillWatchProvisioning:
            return "fulfillWatchProvisioning"
        case .confirmWatchProvisioning:
            return "confirmWatchProvisioning"
        case .batteryLvl:
            return "batteryLvl"
        case .revokeWatchCert:
            return "revokeWatchCert"
        case .requestTerminate:
            return "requestTerminate"
        case .terminateAnswer:
            return "terminateAnswer"
        case .dismissBatteryLow:
            return "dismissBatteryLow"
        }
    }
}
