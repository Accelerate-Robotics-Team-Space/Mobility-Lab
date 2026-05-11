//
//  BleRoutable.swift
//  MobilityLab
//
//  Created by Josh Franco on 9/10/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth

protocol BleSendable {
    func convertToSendable() -> (BleCharacteristic, Data)
}

// Typealias is a convenience for the onFlush var in the SendBuffer
typealias BleBufferFlusher = ((
_ items: [BleSendObj],
_ commit: @escaping () -> Void,
_ rollback: @escaping () -> Void,
_ queue: OperationQueue) -> Void)

/// Is designed so a enum conforms to this protocol so that it can drive BLE connections
protocol BleRoutable {
    /// Is designed to be a enum w/ associated types that correspond to the obj that is being sent (from peripheral/central)
    associatedtype BleChrObj: BleSendable
    
    /// The service of the peripheral/central has multiple characteristics (is a 1 to many relationship)
    var service: BleService { get }
    
    /// The characteristics of the service above (is a many to 1 relationship)
    var characteristics: [BleCharacteristic] { get }
    
    /// Available sizes for the send buffer (how many packets are sent per transmission)
    var bufferSizes: [Int] { get }
    
    /// Primary Service - Standard type of GATT service that includes relevant, standard functionality exposed by the GATT server.
    /// Secondary Service - Intended to be included only in other primary services and makes sense only as its modifier,
    /// having no real meaning on its own.
    /// In practice, secondary services are rarely used.
    var isPrimaryService: Bool { get }
    
    /// Used to decode data from the following delegate callbacks:
    ///  * peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    ///  * peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest])
    /// - Parameters:
    ///   - data: Data to be decoded
    ///   - charId: characteristics ID of the write/value updated
    func decodeData(_ data: Data, for charId: CBUUID) -> BleChrObj?
}

extension BleRoutable {
    var bufferSizes: [Int] {
        return [1]
    }
    
    /// Default implementation of isPrimaryService
    var isPrimaryService: Bool {
        true
    }
    
    /// Cconvenience method to get the default buffer size, its simply the first element in the buffer size arr
    var defaultBufferSize: Int {
        self.bufferSizes[self.bufferSizes.startIndex]
    }
    
    /// Constructs a send buffer for the central/peripheral
    /// - Parameters:
    ///   - size: Size of the buffer (defaults to defaultBufferSize)
    ///   - oldBuffer: Optional old buffer to get autoFlush bool
    ///   - flusher: BleBufferFlusher that defines how the send buffer handles the onFlush callback
    /// - Returns: a send buffer for the central/peripheral to use
    func constructBuffer(with size: Int? = nil, using oldBuffer: SendBuffer<BleSendObj>?,
                         using flusher: @escaping BleBufferFlusher) -> SendBuffer<BleSendObj> {
        oldBuffer?.flush()
        
        let newBuffer = SendBuffer<BleSendObj>(bufferSize: size ?? defaultBufferSize)
        newBuffer.autoFlush = oldBuffer?.autoFlush ?? false
        newBuffer.onFlush = flusher
        
        return newBuffer
    }
}
