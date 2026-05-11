//
//  BLEPeripheralDriver.swift
//  MobilityLab WatchKit Extension
//
//  Created by Vadym Riznychok on 8/31/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import Foundation

typealias BLEPeripheralDriverDelegateAndStorage = BLEPeripheralDriverDelegate & BLEPeripheralStorage

protocol BLEPeripheralStorage: NSObjectProtocol {
    var peripherals: Set<CBPeripheral> { get set }
}

protocol BLEPeripheralDriverDelegate: NSObjectProtocol {
    func didSubscribeToCharectiristics(of peripheral: CBPeripheral)
    func peripheralInvalidated(peripheral: CBPeripheral)

    func didReceiveData(_ data: Data, packetDescription: CBUUID, peripheral: CBPeripheral)
    func flashBuffer()
    func reset()
}

class BLEPeripheralDriver: NSObject {
    private weak var delegate: BLEPeripheralDriverDelegateAndStorage?
    private let router: BleDataFeedRouter
    private var periphChars: [UUID: [CBCharacteristic]] = [:]
    private var rssiValues: [Int] = []
    private let capacity = 20

    init(delegate: BLEPeripheralDriverDelegateAndStorage, router: BleDataFeedRouter) {
        self.delegate = delegate
        self.router = router
    }

    private func log(_ str: String) {
        logger.debug("[BLE] \(str)")
    }

    private func handleError(_ error: Error?, method: String? = nil) -> Bool {
        guard let error = error else { return true }

        logger.error("Error \(method ?? ""): \(error.localizedDescription)")
        return false
    }

    private func handleErrorAndCleanUp(_ error: Error?, method: String? = nil) -> Bool {
        guard handleError(error) else {
//            delegate?.reset()
            return false
        }
        return true
    }
}

extension BLEPeripheralDriver: CBPeripheralDelegate {
    /// The Router Service was discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard handleErrorAndCleanUp(error, method: "discovering services") else { return }

        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(router.characteristics.map({ $0.uuid }), for: service)
        }
    }

    /// The Router characteristic was discovered.
    /// Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard handleErrorAndCleanUp(error, method: "discovering characteristics") else { return }

        // Again, we loop through the array, just in case and check if it's the right one
        // Here is where we have to modify for the system to handle multiple wearables
        logger.debug("didDiscoverCharacteristicsFor \(peripheral.identifier.uuidString)")
        delegate?.peripherals.insert(peripheral)
        periphChars.updateValue([], forKey: peripheral.identifier)

        for characteristic in (service.characteristics ?? []) where router.characteristics.contains(where: { $0.uuid == characteristic.uuid }) {
            peripheral.setNotifyValue(true, for: characteristic)

            delegate?.flashBuffer()
        }
        if periphChars[peripheral.identifier]?.count == router.characteristics.count {
            log("Connected chars to \(peripheral.name ?? "")")
        }
    }

    /// The peripheral letting us know whether our subscribe/unsubscribe happened or not
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard handleError(error, method: "changing notification state") else { return }

        // Exit if it's not the transfer characteristic
        guard router.characteristics.contains(where: { $0.uuid == characteristic.uuid }) else { return }

        if characteristic.isNotifying {
            // Notification has started
            var periphArary = periphChars[peripheral.identifier] ?? []
            periphArary.append(characteristic)
            periphChars.updateValue(periphArary, forKey: peripheral.identifier)
            if periphChars[peripheral.identifier]?.count == router.characteristics.count {
                delegate?.didSubscribeToCharectiristics(of: peripheral)
                log("Did subscribe to characteristics of \(peripheral.name ?? "")")
            }
        } else {
            // Notification has stopped, so disconnect from the peripheral
            var periphChar = periphChars[peripheral.identifier] ?? []
            if let charInd = periphChar.firstIndex(where: { $0.uuid == characteristic.uuid }) {
                periphChar.remove(at: charInd)
            }
            periphChars.updateValue(periphChar, forKey: peripheral.identifier)
            if periphChars[peripheral.identifier]?.isEmpty == true {
                delegate?.peripheralInvalidated(peripheral: peripheral)
                log("Did stop notifications on characteristics of \(peripheral.name ?? "")")
            }
        }
    }

    /// The peripheral letting us know when services have been invalidated.
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        if invalidatedServices.isEmpty {
            log("Rediscover services")
            peripheral.discoverServices([router.service.uuid])
        } else {
            log("Peripheral service is invalidated")
            delegate?.peripheralInvalidated(peripheral: peripheral)
        }
    }

    /// This callback lets us know more data has arrived via notification on the characteristic
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard handleErrorAndCleanUp(error, method: "updating value for char") else { return }

        if let charData = characteristic.value {
            delegate?.didReceiveData(charData, packetDescription: characteristic.uuid, peripheral: peripheral)
        } else {
            log("BLE Central could not update value due to characteristic having no value")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		logger.error("Error writing \(error.debugDescription)")
    }

    /// This is called when peripheral is ready to accept more data when using write without response
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        delegate?.flashBuffer()
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error {
            logger.error("⚠️ RSSI read failed: \(error.localizedDescription)")
            return
        }
        enqueue(RSSI.intValue)
        let pastValues = "Past RSSIs: \(rssiValues.map(String.init).joined(separator: ", "))"
        logger.event("didReadRSSI Info: \(peripheral.logDescription) latest RSSI:\(RSSI.intValue) dBm \(pastValues)")
    }

    private func enqueue(_ newValue: Int) {
        guard rssiValues.last != newValue else {
            return
        }
        rssiValues.append(newValue)
        if rssiValues.count > capacity {
            rssiValues.removeFirst()
        }
    }

}
