// swiftlint:disable:this file_name
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

enum LogState {
    case syncing, synced, failed
}

enum SyncingLogsState {
    case none, syncing, failed
}

enum PatientMonitorState: String {
    case onStart
    case onResume
    case onPause

    var buttonText: String {
        switch self {
        case .onStart:
            return R.string.localizable.startMonitoring()
        case .onResume:
            return "Pause Monitoring"
        case .onPause:
            return R.string.localizable.resume()
        }
    }
}

enum PatientAlert {
    case wrongPosition
    case timeToTurn(nextPosition: PositionalFlagCategory)
    case sensorLowBattery
    case patchExpired
    case sensorDisconnect
    case sensorDisconnectOver1Hour
    case longSwapPeriod
    case longPausePeriod
    case rePairSensor
}

extension PatientAlert: Hashable {
    static func == (lhs: PatientAlert, rhs: PatientAlert) -> Bool {
        switch (lhs, rhs) {
        case (.wrongPosition, .wrongPosition),
             (.sensorLowBattery, .sensorLowBattery),
             (.patchExpired, .patchExpired),
             (.sensorDisconnect, .sensorDisconnect),
             (.sensorDisconnectOver1Hour, .sensorDisconnectOver1Hour),
             (.longSwapPeriod, .longSwapPeriod),
             (.longPausePeriod, .longPausePeriod),
             (.rePairSensor, .rePairSensor):
            true
        // case (.timeToTurn(let lhsPosition), .timeToTurn(nextPosition: let rhsPosition)):
        //    lhsPosition == rhsPosition
        case (.timeToTurn, .timeToTurn):
            true
        default:
            false
        }
    }
}
