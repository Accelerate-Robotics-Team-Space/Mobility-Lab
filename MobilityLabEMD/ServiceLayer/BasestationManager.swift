//
//  BasestationManager.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 12/29/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol BasestationManagerProtocol {
    @MQTTActor func subscribe(to listOfBmm: [String])
    func reset()
    @MQTTActor  func unsubscribe()
}

extension Container {
    var basestationManager: Factory<BasestationManagerProtocol> {
        self { BasestationManager() }
            .cached
    }
}

class BasestationManager: BasestationManagerProtocol {
    private let router = MqttRouter(for: DataFeedTopics.self)
    @Injected(\.securityService) 
    private var securityService

    @MQTTActor
    func subscribe(to listOfBmm: [String]) {
        if securityService.isDeviceRegistered {
            router.startSessionIfNeeded { [weak self] in
                for bmm in listOfBmm {
                    self?.router.subscribe(to: .batteryLvl(baseStationId: bmm.uppercased()))
                    self?.router.subscribe(to: .wearableBatteryLvl(baseStationId: bmm.uppercased()))
                    self?.router.subscribe(to: .patientInfo(baseStationId: bmm.uppercased()))
                    self?.router.subscribe(to: .patientLocation(baseStationId: bmm.uppercased()))
                    self?.router.subscribe(to: .dataObservation(baseStationId: bmm.uppercased()))
                    self?.router.subscribe(to: .sessionObservation(baseStationId: bmm.uppercased()))
                }
            }
        }
    }

    func reset() {
        router.reset()
    }

    @MQTTActor
    func unsubscribe() {
        router.unsubscribe()
    }
}
