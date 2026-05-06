//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import Foundation
@testable import SensorSuite_BMM

final class MockBlePeripheral<T: BleRoutable>: BlePeripheralProtocol {
    typealias Router = T

    var router: T
    var sendBuffer: SendBuffer<BleSendObj>?
    var peripheralManager: CBPeripheralManager?
    var packetDict: [String: BlePacket] = [:]
    var subscribedChars: [UUID: Set<CBCharacteristic>] = [:]
    var state: PeripheralState = .waitingToConnect

    var startHandler: (() -> Void)?
    var unpairHandler: (() -> Void)?
    var terminateHandler: (() -> Void)?
    var characteristicHandler: ((CBUUID) -> CBMutableCharacteristic)?
    var appendSubscribedCentralsHandler: ((UUID) -> Void)?
    var observeStateUpdateHandler: (((PeripheralState) -> Void) -> Void)?
    var observeValueUpdateHandler: (((T.BleChrObj, UUID) -> Void) -> Void)?
    var evaluatePacketHandler: ((Data, String, (Data?) -> Void) -> Void)?
    var updateBufferHandler: ((Int) -> Void)?
    var activateBufferFlushHandler: ((Bool) -> Void)?
    var queueObjHandler: ((BleSendObj, ((Result<(), any Error>) -> Void)?) -> Void)?
    var queueCharHandler: ((T.BleChrObj, ((Result<(), any Error>) -> Void)?) -> Void)?

    init(_ router: T = BleDataFeedRouter.std) {
        self.router = router
    }

    func start() {
        guard let startHandler else {
            fatalError("startHandler must be set")
        }
        startHandler()
    }
    
    func unpair() {
        guard let unpairHandler else {
            fatalError("unpairHandler must be set")
        }
        unpairHandler()
    }
    
    func terminate() {
        guard let terminateHandler else {
            fatalError("terminateHandler must be set")
        }
        terminateHandler()
    }
    
    func characteristic(with id: CBUUID) -> CBMutableCharacteristic? {
        guard let characteristicHandler else {
            fatalError("characteristicHandler must be set")
        }
        return characteristicHandler(id)
    }
    
    func appendSubscribedCentrals(newCentral: UUID) {
        guard let appendSubscribedCentralsHandler else {
            fatalError("appendSubscribedCentralsHandler must be set")
        }
        appendSubscribedCentralsHandler(newCentral)
    }
    
    func observeStateUpdate(completion: @escaping (PeripheralState) -> Void) {
        guard let observeStateUpdateHandler else {
            fatalError("observeStateUpdateHandler must be set")
        }
        observeStateUpdateHandler(completion)
    }
    
    func observeValueUpdate(completion: @escaping (T.BleChrObj, UUID) -> Void) {
        guard let observeValueUpdateHandler else {
            fatalError("observeValueUpdateHandler must be set")
        }
        observeValueUpdateHandler(completion)
    }

    func evaluatePacketData(_ someData: Data, packetDescription: String, completion: @escaping (Data?) -> Void) {
        guard let evaluatePacketHandler else {
            fatalError("evaluatePacketHandler must be set")
        }
        evaluatePacketHandler(someData, packetDescription, completion)
    }

    func updateBuffer(with size: Int) {
        guard let updateBufferHandler else {
            fatalError("updateBufferHandler must be set")
        }
        updateBufferHandler(size)
    }

    func activateBufferFlush(_ activated: Bool) {
        guard let activateBufferFlushHandler else {
            fatalError("activateBufferFlushHandler must be set")
        }
        activateBufferFlushHandler(activated)
    }

    func queueObj(_ obj: BleSendObj, result: ((Result<(), any Error>) -> Void)?) {
        guard let queueObjHandler else {
            fatalError("queueObjHandler must be set")
        }
        queueObjHandler(obj, result)
    }

    func queueChar(_ char: T.BleChrObj, result: ((Result<(), any Error>) -> Void)?) {
        guard let queueCharHandler else {
            fatalError("queueCharHandler must be set")
        }
        queueCharHandler(char, result)
    }
}

final class NullBlePeripheral<T: BleRoutable>: BlePeripheralProtocol {
    typealias Router = T

    var router: T
    var sendBuffer: SendBuffer<BleSendObj>?
    var peripheralManager: CBPeripheralManager?
    var packetDict: [String: BlePacket] = [:]
    var subscribedChars: [UUID: Set<CBCharacteristic>] = [:]
    var state: PeripheralState = .waitingToConnect

    init(_ router: T) {
        self.router = router
    }

    func start() {
        fatalError("Null Service Should Not Be Used")
    }

    func unpair() {
        fatalError("Null Service Should Not Be Used")
    }

    func terminate() {
        fatalError("Null Service Should Not Be Used")
    }

    func characteristic(with id: CBUUID) -> CBMutableCharacteristic? {
        fatalError("Null Service Should Not Be Used")
    }

    func appendSubscribedCentrals(newCentral: UUID) {
        fatalError("Null Service Should Not Be Used")
    }

    func observeStateUpdate(completion: @escaping (PeripheralState) -> Void) {
        fatalError("Null Service Should Not Be Used")
    }

    func observeValueUpdate(completion: @escaping (T.BleChrObj, UUID) -> Void) {
        fatalError("Null Service Should Not Be Used")
    }

    func evaluatePacketData(_ someData: Data, packetDescription: String, completion: @escaping (Data?) -> Void) {
        fatalError("Null Service Should Not Be Used")
    }

    func updateBuffer(with size: Int) {
        fatalError("Null Service Should Not Be Used")
    }

    func activateBufferFlush(_ activated: Bool) {
        fatalError("Null Service Should Not Be Used")
    }

    func queueObj(_ obj: BleSendObj, result: ((Result<(), any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }

    func queueChar(_ char: T.BleChrObj, result: ((Result<(), any Error>) -> Void)?) {
        fatalError("Null Service Should Not Be Used")
    }
}
