//
//  BlePeripheral+DataTransfer.swift
//  MobilityLab BMM
//
//  Created by Vadym Riznychok on 9/6/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import Foundation

// MARK: - Private

private extension BlePeripheral {
    func peripheralFlusher() -> BleBufferFlusher {
        return { [weak self] items, commit, rollback, _ in
            guard let self = self, let manager = self.peripheralManager else { return }
            self.transmitItems(items, manager: manager) { finalStatus in
                if finalStatus == .error {
                    rollback()
                } else {
                    commit()
                }
            }
        }
    }

    func transmitItems(_ items: [BleSendObj], manager: CBPeripheralManager, completion: @escaping (BLESequence) -> Void) {
        var remainingItems = items
        guard let itemToTransmit = remainingItems.popLast() else {
            return completion(.end)
        }

        if let char = characteristic(with: itemToTransmit.characteristic.uuid) {
            let packet = BlePacket(data: itemToTransmit.sendData)
            packet.delegate = self
            packet.transmit(using: manager, char: char) { finalStatus in
                if finalStatus == .error {
                    return completion(.error)
                } else {
                    self.transmitItems(remainingItems,
                                       manager: manager,
                                       completion: completion)
                }
            }
        } else {
            transmitItems(remainingItems,
                          manager: manager,
                          completion: completion)
        }
    }
}

// MARK: - Transmit Methods
extension BlePeripheral {
    func evaluatePacketData(_ someData: Data, packetDescription: String, completion: @escaping (Data?) -> Void) {
        let packet = packetDict[packetDescription] ?? BlePacket()
        packet.receiveData(someData) { result in
            switch result {
            case .success(let data):
                self.packetDict.removeValue(forKey: packetDescription)
                return completion(data)
            case .needMoreData:
                self.packetDict[packetDescription] = packet
                return completion(nil)
            case .failure:
                self.packetDict.removeValue(forKey: packetDescription)
                return completion(nil)
            }
        }
    }

    /// Queue some a Send Obj to be sent to the peripheral
    /// - Parameters:
    ///   - obj: Object to be sent
    ///   - result: result of the send, the instance must be subscirbed to the characteristic via its router
    func queueObj(_ obj: BleSendObj, result: ((Result<(), Error>) -> Void)? = nil) {
        guard characteristic(with: obj.characteristic.uuid) != nil else {
            result?(.failure(NetworkingError.BLE.notSubscribed))
            return
        }

        self.sendBuffer?.add(obj)
        result?(.success(()))
    }

    /// Queue some Serializable that conforms to BleSerializable
    /// - Parameters:
    ///   - serializable: The obj (that conforms to BleSerializable) that we want to queue up
    ///   - char: The characteristic of the obj NOTE: cannot queue a obj if the peripheral does not subscribe to that characteristic
    ///   Defaults to the default characteristic defined by BleSerializable
    ///   - result: Optinal result of the method, will fail if the peripheral is not subscirbed to that characteristic
    func queueChar(_ char: T.BleChrObj, result: ((Result<(), Error>) -> Void)? = nil) {
        let (characteristic, data) = char.convertToSendable()

        queueObj(BleSendObj(characteristic: characteristic,
                            sendData: data,
                            specificPeripheralId: nil),
                 result: result)
    }

    /// Update the send buffer with a new buffer that has a given size, NOTE: cannot update to a new buffer with the same size
    /// - Parameter size: Size of the new buffer
    func updateBuffer(with size: Int) {
        guard (sendBuffer?.size ?? 0) != size else { return }

        sendBuffer = router.constructBuffer(with: size, using: sendBuffer, using: peripheralFlusher())
    }

    func activateBufferFlush(_ activated: Bool) {
        guard sendBuffer?.autoFlush != activated else { return }

        sendBuffer?.autoFlush = activated
        if activated { sendBuffer?.flush() }
    }
}
