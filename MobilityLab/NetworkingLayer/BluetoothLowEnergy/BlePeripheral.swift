//
//  BlePeripheral.swift
//  MobilityLab
//
//  Created by Josh Franco on 8/28/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import FactoryKit
import Foundation

protocol BlePeripheralProtocol: AnyObject {
    associatedtype Router: BleRoutable
    var router: Router { get }
    var sendBuffer: SendBuffer<BleSendObj>? { get set }
    var peripheralManager: CBPeripheralManager? { get set }
    var packetDict: [String: BlePacket] { get set }
    var subscribedChars: [UUID: Set<CBCharacteristic>] { get set }
    var state: PeripheralState { get }
    func start()
    func unpair()
    func terminate()
    func characteristic(with id: CBUUID) -> CBMutableCharacteristic?
    func appendSubscribedCentrals(newCentral: UUID)
    func observeStateUpdate(completion: @escaping (PeripheralState) -> Void)
    func observeValueUpdate(completion: @escaping (Router.BleChrObj, UUID) -> Void)
    func evaluatePacketData(_ someData: Data, packetDescription: String, completion: @escaping (Data?) -> Void)
    func queueObj(_ obj: BleSendObj, result: ((Result<(), Error>) -> Void)?)
    func queueChar(_ char: Router.BleChrObj, result: ((Result<(), Error>) -> Void)?)
    func queueObj(_ obj: BleSendObj)
    func queueChar(_ char: Router.BleChrObj)
    func updateBuffer(with size: Int)
    func activateBufferFlush(_ activated: Bool)
}

extension BlePeripheralProtocol {
    func queueObj(_ obj: BleSendObj) {
        queueObj(obj, result: nil)
    }

    func queueChar(_ char: Router.BleChrObj) {
        queueChar(char, result: nil)
    }
}

class BlePeripheral<T: BleRoutable>: NSObject, CBPeripheralManagerDelegate, BlePeripheralProtocol {
    typealias Router = T
    let router: T
    var sendBuffer: SendBuffer<BleSendObj>?
    var peripheralManager: CBPeripheralManager?
    var packetDict: [String: BlePacket] = [:]

    private var subscribedCentrals: Set<UUID> = []
    var subscribedChars: [UUID: Set<CBCharacteristic>] = [:] {
        didSet {
            logger.debug("🕸️ subs chars count \(subscribedChars.keys.map({ "\($0.uuidString) : \(subscribedChars[$0]?.count ?? 0) " }))")
        }
    }

    private(set) var state: PeripheralState = .waitingToConnect {
        didSet {
            self.stateCompletion(state)
        }
    }
    private var stateCompletion: (PeripheralState) -> Void = { _ in }
    private var valueUpdateCompletion: (T.BleChrObj, UUID) -> Void = { _, _ in }
    private var managerIsReady: () -> Void = {}
    private var characteristics: [CBMutableCharacteristic] = []

    // MARK: Services
    @Injected(\.patientManager) private var patientManager

    // MARK: - Init
    init(for newRouter: T) {
        router = newRouter
        super.init()
        
        updateBuffer(with: router.defaultBufferSize)
    }
    
    // MARK: - Util
    func start() {
        guard peripheralManager == nil else { return }
        
        peripheralManager = CBPeripheralManager(delegate: self,
                                                queue: nil,
                                                options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }

    /// Build our service.
    private func setupPeripheral() {
        // Save characteristics
        let chars = router.characteristics.map({ $0.constructChar })

        // add the characteristic to the service.
        let newService = router.constructService(with: chars)

        // And add it to the peripheral manager.
        peripheralManager?.add(newService)

        characteristics = chars
    }
    
    private func removeServices() {
        peripheralManager?.removeAllServices()
        state = .advertising
        setupPeripheral()
        peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [router.service.uuid]])
    }
    
    func unpair() {
        subscribedCentrals.forEach({ state = .unpaired(id: $0) })
        subscribedCentrals.removeAll()
    }
    
    func terminate() {
        peripheralManager?.stopAdvertising()
        peripheralManager?.removeAllServices()
        peripheralManager = nil
        subscribedChars.removeAll()
        unpair()
    }

    func characteristic(with id: CBUUID) -> CBMutableCharacteristic? {
        return characteristics.first(where: { $0.uuid == id })
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    /// Required protocol method.  A full app should take care of all the possible states,
    /// but we're just waiting for to know when the CBPeripheralManager is ready
    ///
    /// Starting from iOS 13.0, if the state is CBManagerStateUnauthorized, you
    /// are also required to check for the authorization state of the peripheral to ensure that
    /// your app is allowed to use bluetooth
    /// - Parameter peripheral: Core Bluetooth Peripheral
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else {
            let connectionErr: Error
            
            switch peripheral.state {
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
            
            logger.error("needs state: .PoweredOn but got \(peripheral.state.rawValue) /n Err: \(connectionErr.localizedDescription)")
            state = .advertisingError(err: connectionErr)
            return
        }
        
        log("BLE powered on")
        state = .advertising
        setupPeripheral()
        peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [router.service.uuid]])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            logger.error("Error Starting Advertising: \(error.localizedDescription)")
            return
        }
        
        log("Peripheral Started Advertising")
        state = .waitingToConnect
    }
    
    /// Catch when someone subscribes to our characteristic, then start sending them data
    /// - Parameters:
    ///   - peripheral: Peripheral that owns the characteristic
    ///   - central: Connected Central
    ///   - characteristic: Characteristic that was subscribed too
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        guard canConnect(newCentralId: central.identifier) else { return }

        var chars = subscribedChars[central.identifier] ?? []
        chars.insert(characteristic)
        subscribedChars.updateValue(chars, forKey: central.identifier)

        state = .connected(id: central.identifier, characteristic: characteristic)

        // save central
        subscribedCentrals.insert(central.identifier)
        
        // Start auto flush & flush any data we have
        activateBufferFlush(true)
    }
    
    /// Recognize when the central unsubscribes
    /// - Parameters:
    ///   - peripheral: Peripheral that is unsubscribing
    ///   - central: central that is unsubscribing
    ///   - characteristic: characteristic that is being unsubscribed from
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        guard canConnect(newCentralId: central.identifier) else { return }

        var chars = subscribedChars[central.identifier] ?? []
        chars.remove(characteristic)
        subscribedChars.updateValue(chars, forKey: central.identifier)

        if chars.isEmpty {
            subscribedCentrals.remove(central.identifier)
            state = .disconnected(id: central.identifier)
        }
        if subscribedCentrals.isEmpty {
            activateBufferFlush(false)
        }
    }
    
    /// This callback comes in when the PeripheralManager is ready to send the next chunk of data.
    /// This is to ensure that packets will arrive in the order they are sent
    /// - Parameter peripheral: peripheral to update subscribers
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Start auto flush & flush any data we have
        managerIsReady()
        activateBufferFlush(true)
    }
    
    /// This callback comes in when the PeripheralManager received write to characteristics
    /// - Parameters:
    ///   - peripheral: Peripheral that received the requests
    ///   - requests: requests to receive a write
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard
                characteristics.contains(where: { $0.uuid == request.characteristic.uuid }),
                let requestData = request.value else { continue }
            
            evaluatePacketData(requestData, packetDescription: request.characteristic.uuid.uuidString) { evaluatedData in
                let uuid = request.characteristic.uuid
                guard
                    let evaluatedData = evaluatedData,
                    let decodedObj = self.router.decodeData(evaluatedData, for: uuid) else { return }
                
                self.valueUpdateCompletion(decodedObj, request.central.identifier)
            }
        }
    }
    
    // MARK: - Helpers
    func appendSubscribedCentrals(newCentral: UUID) {
        subscribedCentrals.insert(newCentral)
    }
    
    func observeStateUpdate(completion: @escaping (PeripheralState) -> Void) {
        stateCompletion = completion
    }
    
    func observeValueUpdate(completion: @escaping (T.BleChrObj, UUID) -> Void) {
        valueUpdateCompletion = completion
    }

    private func canConnect(newCentralId: UUID) -> Bool {
        guard let connectedId = isBinded(), connectedId != newCentralId else {
            return true
        }
        if case.disconnected = patientManager.session?.blePeripheral.state {
            return true
        } else {
            return false
        }
    }

    private func isBinded() -> UUID? {
        if case .connected(let id, _) = patientManager.session?.blePeripheral.state {
            return id
        } else if case .disconnected(let id) = patientManager.session?.blePeripheral.state {
            return id
        }
        return nil
    }

    /// Method to log a string with a prefix
    /// - Parameter str: String to log
    private func log(_ str: String) {
        logger.debug("[\(router)] \(str)")
    }
}

// MARK: - BlePacketDelegate
extension BlePeripheral: BlePacketDelegate {
    func managerIsReady(completion: @escaping () -> Void) {
        managerIsReady = completion
    }
}
