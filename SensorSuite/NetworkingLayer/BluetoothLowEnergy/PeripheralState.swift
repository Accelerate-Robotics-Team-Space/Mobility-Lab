//
//  PeripheralState.swift
//  SensorSuite BMM
//
//  Created by Vadym Riznychok on 9/6/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import Foundation

enum PeripheralState {
    case waitingToConnect
    case advertising
    case connected(id: UUID, characteristic: CBCharacteristic)
    case disconnected(id: UUID)
    case unpaired(id: UUID)
    case terminate
    case advertisingError(err: Error)

    var description: String {
        switch self {
        case .waitingToConnect:
            return "Bluetooth LE is waiting to connect..."
        case .advertising:
            return "Peripheral started Advertising"
        case .connected(let id, _):
            return "Data requester is connected... \(id.uuidString)"
        case .disconnected(let id):
            return "Data requester is disconnected... \(id.uuidString)"
        case .unpaired(let id):
            return "Data requester is unpaired... \(id.uuidString)"
        case .terminate:
            return "Data requester is terminated"
        case .advertisingError(err: let err):
            return err.localizedDescription
        }
    }
}
