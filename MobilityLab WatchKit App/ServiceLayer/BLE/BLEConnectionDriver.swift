//
//  BLEConnectionDriver.swift
//  MobilityLab WatchKit Extension
//
//  Created by Vadym Riznychok on 8/30/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import Foundation

enum BMMSessionState {
    case idle
    case searching
    case active
    case reconnecting
}

class BLEConnectionDriver: NSObject, BLEPeripheralStorage {
    let router: BleDataFeedRouter
    var transmitter: BLEDataTransmitter?
    private var centralDriver: BLECentralManagerDriver?
    private var peripheralDriver: BLEPeripheralDriver?

    var peripherals: Set<CBPeripheral> = [] {
        didSet {
            logger.debug("🕸️ peripherals \(peripherals.map({ $0.name }))")
        }
    }
    var pairedPeripheral: CBPeripheral?
    private var disconnectionTask: Task<Void, Never>?
    private var sessionState: BMMSessionState = .idle {
        didSet {
            guard sessionState != oldValue || sessionState == .reconnecting else { return }
            stateUpdated(sessionState)
            logger.debug("sessionState \(sessionState)")

            switch sessionState {
            case .idle:
                reset()
                invalidateDisconnection()
            case .searching:
					logger.info("Searching")
            case .active:
                centralDriver?.stopScan()
                if let paired = pairedPeripheral {
                    peripherals = [paired]
                }
                invalidateDisconnection()
            case .reconnecting:
                if let paired = pairedPeripheral {
                    logger.debug("reconnecting pairedPeripheral:\(paired)")
                    peripherals = [paired]
                    centralDriver?.reconnectPaired(peripheral: paired)
                }
                invalidateDisconnection()
                disconnectionTask = Task { [weak self] in
                    do {
                        try await Task.sleep(until: .now + .seconds(3600), clock: .continuous)
                        self?.sessionState = .idle
                    } catch {
                        // ??
                    }
                }
            }
        }
    }

    var stateUpdated: (BMMSessionState) -> Void = { _ in }
    var valueUpdated: (BleDataFeedRouter.BleChrObj, UUID) -> Void = { _, _ in }

    private let userDefaults: UserDefaults = .standard
    // TODO: Inject with FactoryKit when available
    private let deviceMotionManager: DeviceMotionManagerProtocol = DeviceMotionManager.shared

    // MARK: - Init
    init(router: BleDataFeedRouter) {
        self.router = router
        super.init()
        transmitter = BLEDataTransmitter(router: router, dataSource: self)
        centralDriver = BLECentralManagerDriver(delegate: self, router: router)
        peripheralDriver = BLEPeripheralDriver(delegate: self, router: router)
    }

    func scanForPeripherals() {
        logger.debug("scanForPeripherals")
        centralDriver?.startScan()
        sessionState = .searching
    }

    func stopScan() {
        logger.debug("stopScan")
        centralDriver?.stopScan()
        transmitter?.queueChar(.requestTerminate(request: JustRequest()))
    }

    func reset() {
        logger.debug("reset BLE")
        stopScan()
        transmitter?.cleanup()
        centralDriver?.disconnectAll()
        peripherals.removeAll()
        pairedPeripheral = nil
        if sessionState != .idle {
            sessionState = .idle
        }
    }

    func confirmConnection(id: UUID, wearableLocation: WearableLocation) {
        peripherals.forEach { peripheral in
            var isConfirmed = false
            defer {
                if isConfirmed {
                    pairedPeripheral = peripheral
                    sessionState = .active
                    let batteryData = BatteryLevelData(
                        batteryLvl: UInt8(WatchConstants.watchBatteryPercentage),
                        wearableId: userDefaults.wearableId
                    )
                    transmitter?.queueChar(.batteryLvl(data: batteryData))
                }
            }

            if peripheral.identifier == id, peripheral.state == .connected {
                isConfirmed = true
            } else {
                centralDriver?.disconnect(peripheral: peripheral)
            }

            logger.debug("\(isConfirmed ? "confirm" : "decline") connection \(peripheral.identifier.uuidString)")
            let confirmation = DataFeedConfirmation(
                wearableId: isConfirmed ? userDefaults.wearableId : nil,
                wearableGuuid: isConfirmed ? userDefaults.wearableGuid : nil,
                location: wearableLocation,
                version: WatchConstants.versionNumStr
            )
            transmitter?.queueChar(.confirmDataFeed(confirmation: confirmation), to: peripheral.identifier)
        }
    }

    func declineConnection(wearableId: String, peripheralId: UUID) {
        if wearableId == userDefaults.wearableId {
            if let peripheral = peripherals.first(where: { $0.identifier == peripheralId }) {
                centralDriver?.disconnect(peripheral: peripheral)
                logger.debug("declineConnection per: \(peripheralId), wer: \(wearableId)")
            }
        }
    }

    func declineUnpairedConnections() {
        peripherals.forEach { peripheral in
            guard peripheral.identifier != pairedPeripheral?.identifier else { return }

            logger.debug(peripheral.logDescription)
            let confirmation = DataFeedConfirmation(
                wearableId: nil,
                wearableGuuid: nil,
                location: .chest,
                version: WatchConstants.versionNumStr
            )
            transmitter?.queueChar(.confirmDataFeed(confirmation: confirmation), to: peripheral.identifier)
            centralDriver?.disconnect(peripheral: peripheral)
        }
    }

    func sendCalibrationPoint() {
        transmitter?.queueChar(.calibrationPoint(calibrationPoint: deviceMotionManager.getDataPoint()))
    }

    private func invalidateDisconnection() {
        logger.debug("Invalidate Disconnection")
        disconnectionTask?.cancel()
        disconnectionTask = nil
    }
}

extension BLEConnectionDriver: BLECentralManagerDelegate {
    func centralManagerDidUpdateState(_ state: BLECentralManagerState) {
        logger.event("State \(state)")
        switch state {
        case .poweredOn:
            scanForPeripherals()
        case .error:
            sessionState = .idle
        }
    }

    func expectedPeripheral() -> CBPeripheral? {
        return pairedPeripheral
    }

    func didConnect(peripheral: CBPeripheral) {
        logger.event("\(peripheral.logDescription)")
        peripherals.insert(peripheral)

        // Make sure we get the discovery callbacks
        peripheral.delegate = peripheralDriver

        // Search only for services that match our UUID
        peripheral.discoverServices([router.service.uuid])
    }

    func didDisconnect(peripheral: CBPeripheral) {
        if pairedPeripheral?.identifier == peripheral.identifier {
            logger.event("Reconnecting \(peripheral.logDescription)")
            sessionState = .reconnecting
        } else {
            logger.event("Removing \(peripheral.logDescription)")
            peripherals.remove(peripheral)
        }
    }
}

extension BLEConnectionDriver: BLEPeripheralDriverDelegate {
    func didSubscribeToCharectiristics(of peripheral: CBPeripheral) {
        if sessionState == .reconnecting || sessionState == .active, pairedPeripheral?.identifier == peripheral.identifier {
            if peripheral == pairedPeripheral && sessionState == .reconnecting {
                sessionState = .active
            }
            return
        }
        let newRequest = DataFeedRequest(wearableId: userDefaults.wearableId, peripheralId: peripheral.identifier.uuidString)
        transmitter?.queueChar(.requestDataFeed(request: newRequest), to: peripheral.identifier)
        transmitter?.sendBuffer?.flush()
    }

    func peripheralInvalidated(peripheral: CBPeripheral) {
        centralDriver?.disconnect(peripheral: peripheral)
        if peripheral == pairedPeripheral {
            pairedPeripheral = nil
            sessionState = .idle
        }
    }

    func didReceiveData(_ data: Data, packetDescription: CBUUID, peripheral: CBPeripheral) {
        transmitter?.evaluatePacketData(data, packetDescription: packetDescription.uuidString) { evaluatedData in
            guard let evaluatedData = evaluatedData,
                    let decodedObj = self.router.decodeData(evaluatedData, for: packetDescription) else {
                logger.info("Error decoding received packet")
                return
            }

            logger.info("Received value:\(peripheral.logDescription) \(packetDescription.uuidString)")
            self.valueUpdated(decodedObj, peripheral.identifier)
        }
    }

    func flashBuffer() {
        transmitter?.sendBuffer?.autoFlush = true
        transmitter?.sendBuffer?.flush()
    }
}

extension CBPeripheral {
    var logDescription: String {
        let id = self.identifier.uuidString
        let name = self.name ?? "Unknown Name"
        let state = "State \(self.state.rawValue)"
        return name + " " + id + " " + state
    }
}
