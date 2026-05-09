//
//  DevSensorDriver.swift
//  MobilityLab
//
//  Created by Josh Franco on 8/19/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

final class DevSensorDriver: ObservableObject {
    @Published var packetsInQueue = 0
    @Published var isBleConnected = false
    @Published var bufferSizeIndex = 0 {
        didSet {
            let newBufferSize = bufferSizes[bufferSizeIndex]
            connectionDriver.transmitter?.updateBuffer(with: newBufferSize)
        }
    }
    
    @Published var isSensing = false {
        didSet {
            if isSensing {
//                self.start()
            } else {
                self.end()
            }
        }
    }
    
    var bufferSizes: [Int] {
        connectionDriver.router.bufferSizes
    }
    
    private(set) var peripheralName: String?
    
    private let motionManager = DeviceMotionManager.shared
    private let connectionDriver = BLEConnectionDriver(router: BleDataFeedRouter.std)
    @Injected(\.notificationCenter) private var notificationCenter

    // MARK: - Init
    init() {
        connectionDriver.stateUpdated = { [weak self] state in
            switch state {
            case .idle, .searching, .reconnecting:
                self?.peripheralName = nil
                self?.isBleConnected = false
            case .active:
                self?.peripheralName = self?.connectionDriver.pairedPeripheral?.name
                self?.isBleConnected = true
            }
        }
    }
}

// MARK: - Private Extension
private extension DevSensorDriver {
    func start() {
        motionManager.initaliseDatasources()
        notificationCenter.addObserver(self, selector: #selector(sendData), name: DeviceMotionManager.newDataNote, object: nil)
    }
    
    func end() {
        motionManager.deinitDatasources()
        connectionDriver.reset()
        
        notificationCenter.removeObserver(self, name: DeviceMotionManager.newDataNote, object: nil)
    }
    
    @objc
    func sendData(notification: NSNotification) {
        guard let data = notification.userInfo as? [String: DataPoint],
              let dataPoint = data["data"] else {
                logger.warn("Could not cast userInfo from notification")
                return
        }

        connectionDriver.transmitter?.queueChar(.dataFeed(dataPoint: dataPoint))
        
        DispatchQueue.main.async { [weak self] in
            self?.packetsInQueue = self?.connectionDriver.transmitter?.sendBuffer?.currentElements.count ?? 0
        }
    }
}
