//
//  BLECentralManagerDriver.swift
//  SensorSuite WatchKit Extension
//
//  Created by Vadym Riznychok on 8/31/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import Foundation

typealias BLECentralManagerDelegateAndStorage = BLECentralManagerDelegate&BLEPeripheralStorage

protocol BLECentralManagerDelegate: NSObjectProtocol {
    func centralManagerDidUpdateState(_ state: BLECentralManagerState)
    func didDisconnect(peripheral: CBPeripheral)
    func didConnect(peripheral: CBPeripheral)
    func expectedPeripheral() -> CBPeripheral?
    func peripheralInvalidated(peripheral: CBPeripheral)
}

enum BLECentralManagerState {
    case poweredOn
    case error(error: Error)
}

class BLECentralManagerDriver: NSObject {
    private weak var delegate: BLECentralManagerDelegateAndStorage?

    private var centralManager: CBCentralManager?
    private let router: BleDataFeedRouter

    private var declinedPeripherals: Set<CBPeripheral> = [] {
        didSet {
            logger.debug("🕸️ declined per \(declinedPeripherals.map({ $0.name }))")
        }
    }

    private var delayedScan = false

    init(delegate: BLECentralManagerDelegateAndStorage, router: BleDataFeedRouter) {
        self.delegate = delegate
        self.router = router
    }

    func retrievedPeripherals() -> [CBPeripheral] {
        logger.debug("retrievedPeripherals")
        return centralManager?.retrieveConnectedPeripherals(withServices: [router.service.uuid]) ?? []
    }

    func startScan() {
        logger.debug("startScan")
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil,
                                              options: [CBCentralManagerOptionShowPowerAlertKey: true])
        }

        guard centralManager?.state == .poweredOn else { return }

        let retrievedPeripherals = retrievedPeripherals()
        retrievedPeripherals
            .filter({ $0.state != .connected })
            .forEach { peripheral in
                log("Connecting to retrieved peripheral \(peripheral.name ?? ""), \(peripheral.state)")

                guard !declinedPeripherals.contains(peripheral) else { return }
                delegate?.peripherals.insert(peripheral)
                centralManager?.connect(peripheral, options: nil)
            }

        scanForPeripherals()
    }

    private func scanForPeripherals() {
        logger.debug("scanForPeripherals")
        centralManager?.scanForPeripherals(withServices: [router.service.uuid],
                                           options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    func reconnectPaired(peripheral: CBPeripheral) {
        logger.debug("reconnectPaired \(peripheral)")
        stopScan()
        centralManager?.connect(peripheral)
    }

    func stopScan() {
        logger.debug("stopScan")
        centralManager?.stopScan()
    }

    func disconnectAll() {
        logger.debug("disconnectAll")
        delegate?.peripherals.forEach({ disconnect(peripheral: $0) })
        retrievedPeripherals().forEach({ disconnect(peripheral: $0) })
        declinedPeripherals.removeAll()
        centralManager = nil
    }

    func disconnect(peripheral: CBPeripheral) {
        logger.debug(peripheral.logDescription)
        declinedPeripherals.insert(peripheral)
        delegate?.peripherals.remove(peripheral)
        guard peripheral.state != .disconnecting else { return }

        for service in peripheral.services ?? [] {
            for char in service.characteristics ?? [] {
                peripheral.setNotifyValue(false, for: char)
            }
        }
        centralManager?.cancelPeripheralConnection(peripheral)
    }

    private func log(_ str: String) {
        logger.debug("\(str)")
    }
}

extension BLECentralManagerDriver: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            let connectionErr: Error

            switch central.state {
            case .unknown:
                connectionErr = NetworkingError.BLE.unknownState
            case .unsupported:
                connectionErr = NetworkingError.BLE.unsupported
            case .unauthorized:
                connectionErr = NetworkingError.BLE.unauthorized
            case .resetting:
                connectionErr = NetworkingError.BLE.resetting
            case .poweredOff:
                connectionErr = NetworkingError.BLE.poweredOff
            default:
                connectionErr = NetworkingError.BLE.unknownErr
            }

            logger.warn("needs state: .PoweredOn but got \(central.state.rawValue). Err: \(connectionErr.localizedDescription)")
            delegate?.centralManagerDidUpdateState(.error(error: connectionErr))
            return
        }

        delegate?.centralManagerDidUpdateState(.poweredOn)
    }

    /// This callback comes whenever a peripheral that is advertising the transfer serviceUUID is discovered.
    /// We check the RSSI, to make sure it's close enough that we're interested in it
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Reject if the signal strength is too low to attempt data transfer.
        // Change the minimum RSSI value depending on your app’s use case.
        logger.debug("Signal Strength: \(RSSI.intValue)")

        let signalStrength = -67

        guard RSSI.intValue >= signalStrength else {
            return
        }

        // Skip connected peripherals
        if retrievedPeripherals()
            .filter({ $0.state != .connected })
            .map({ $0.identifier })
            .contains(peripheral.identifier) {
            return
        }

        // Skip stored peripherals
        if (delegate?.peripherals
            .filter({ $0.state == .connected || $0.state == .connecting })
            .contains(peripheral)) == true {
            return
        }

        // Skip declined peripherals
        if declinedPeripherals.contains(peripheral) { return }

        delegate?.peripherals.insert(peripheral)
        centralManager?.connect(peripheral)
        logger.event("Connecting Peripheral \(peripheral.name ?? "?"), \(peripheral.state) RSSI: \(RSSI.intValue))")
    }

    /// We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard !declinedPeripherals.contains(peripheral) else {
            disconnect(peripheral: peripheral)
            return
        }
        peripheral.readRSSI()
        logger.info("Peripheral Connected \(peripheral.name ?? ""), \(peripheral.state), RSSI: \(peripheral.rssi?.intValue ?? -1)")

        if let expected = delegate?.expectedPeripheral() {
            if peripheral.identifier == expected.identifier {
                delegate?.didConnect(peripheral: peripheral)
            } else {
                disconnect(peripheral: peripheral)
            }
            return
        }

        delegate?.didConnect(peripheral: peripheral)
    }

    /// If the connection fails for whatever reason, we need to deal with it.
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.error("Failed to connect to \(peripheral.name ?? "?"): \(String(describing: error?.localizedDescription))")
        peripheral.readRSSI()
        delegate?.didDisconnect(peripheral: peripheral)
    }

    /// Once the disconnection happens, we need to clean up our local copy of the peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error {
            logger.error("Peripheral Disconnected: \(peripheral.name ?? "?"), error: \(error.localizedDescription)")
        } else {
            logger.warn("Peripheral Disconnected: No Errors: \(peripheral.name ?? "?")")
        }
        peripheral.readRSSI()
        delegate?.didDisconnect(peripheral: peripheral)
    }
}
