//
//  BLEDataTransmitter.swift
//  MobilityLab WatchKit Extension
//
//  Created by Vadym Riznychok on 8/30/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import Foundation

// MARK: - Transmit methods
class BLEDataTransmitter {
    var packetDict: [String: BlePacket] = [:]
    var sendBuffer: SendBuffer<BleSendObj>?
    var dataSource: BLEPeripheralStorage

    private var router: BleDataFeedRouter

    init(router: BleDataFeedRouter, dataSource: BLEPeripheralStorage) {
        self.router = router
        self.dataSource = dataSource
        self.sendBuffer = router.constructBuffer(with: router.defaultBufferSize, using: sendBuffer, using: centralFlusher())
    }

    func centralFlusher() -> BleBufferFlusher {
        return { items, commit, rollback, _ in
            self.transmitItems(items) { finalSequence in
                if finalSequence == .error {
                    rollback()
                } else {
                    commit()
                }
            }
        }
    }

    func evaluatePacketData(_ someData: Data, packetDescription: String, completion: @escaping (Data?) -> Void) {
        let packet = self.packetDict[packetDescription] ?? BlePacket()
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

    /// Queue some Serializable that conforms to BleSerializable
    /// - Parameters:
    ///   - serializable: The obj (that conforms to BleSerializable) that we want to queue up
    ///   - char: The characteristic of the obj NOTE: cannot queue a obj if the centrals router does not subscribe to that characteristic
    ///   Defaults to the default characteristic defined by BleSerializable
    ///   - result: Optinal result of the method, will fail if the centrals router is not subscirbed to that characteristic
    func queueChar(_ char: BleDataFeedRouter.BleChrObj, to peripheralId: UUID? = nil, result: ((Result<(), Error>) -> Void)? = nil) {
        let (characteristic, data) = char.convertToSendable()

        queueObj(BleSendObj(characteristic: characteristic,
                            sendData: data,
                            specificPeripheralId: peripheralId),
                 result: result)
    }

    /// Update the send buffer with a new buffer that has a given size, NOTE: cannot update to a new buffer with the same size
    func updateBuffer(with size: Int) {
        guard (self.sendBuffer?.size ?? 0) != size else { return }

        self.sendBuffer = router.constructBuffer(with: size, using: sendBuffer, using: centralFlusher())
    }

    func cleanup() {
//        sendBuffer?.autoFlush = false
    }
}

// MARK: - Helper Transmit Methods
private extension BLEDataTransmitter {
    private func queueObj(_ obj: BleSendObj, result: ((Result<(), Error>) -> Void)? = nil) {
        guard router.characteristics.contains(obj.characteristic) else {
            result?(.failure(NetworkingError.BLE.notSubscribed))
            return
        }

        self.sendBuffer?.add(obj)
        result?(.success(()))
    }

    private func transmitItems(_ items: [BleSendObj],
                               completion: @escaping (BLESequence) -> Void) {
        var remainingItems = items
        guard let itemToTransmit = remainingItems.popLast() else {
            return completion(.end)
        }

        let correspondingPeripherals: Set<CBPeripheral>
        if let specificPeripheral = dataSource.peripherals.first(where: { $0.identifier == itemToTransmit.specificPeripheralId }) {
            correspondingPeripherals = [specificPeripheral]
        } else {    // Else correspondingPeripherals contains all discoveredPeripherals
            correspondingPeripherals = dataSource.peripherals
        }

        logger.debug("🔊 Sent \(itemToTransmit.characteristic.stringDescription) to: \(correspondingPeripherals.map({ $0.name }))")

        transmitToPeripherals(correspondingPeripherals, item: itemToTransmit) { transmitStatus in
            switch transmitStatus {
            case .error:
                logger.error("transmitStatus error")
                return completion(.error)
            case .end, .none:
                self.transmitItems(remainingItems, completion: completion)
            default:
                return completion(transmitStatus)
            }
        }
    }

    private func transmitToPeripherals(_ peripherals: Set<CBPeripheral>, item: BleSendObj, completion: @escaping (BLESequence) -> Void) {
        var remainingPeripherals = peripherals
        guard let peripheralToTransmit = remainingPeripherals.popFirst() else {
            return completion(.end)
        }

        guard
            let service = peripheralToTransmit.services?.first(where: { $0.uuid == self.router.service.uuid }),
            let char = service.characteristics?.first(where: { $0.uuid == item.characteristic.uuid }) else {
            return completion(.none)
        }

        let packet = BlePacket(data: item.sendData)
        packet.transmit(to: peripheralToTransmit, char: char) { finalStatus in
            if finalStatus == .error {
                return completion(.error)
            } else {
                self.transmitToPeripherals(remainingPeripherals,
                                           item: item,
                                           completion: completion)
            }
        }
    }
}
