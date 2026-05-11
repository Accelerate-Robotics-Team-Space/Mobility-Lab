//
//  PositionsToAvoidDriver.swift
//  MobilityLab
//
//  Created by Josh Franco on 12/8/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

class PositionsToAvoidDriver: ObservableObject {
    @Published var profile: TurningProtocol
    @Published var alertMsg = "?"
    @Published var showAlert = false
    @Published var positionDict: [PositionalFlagCategory: Bool]
    
    private let manager: PatientManagerProtocol

    // exposed for testing
    var cachePatient: ALTPatient {
        manager.cachePatient
    }

    // MARK: - Init
    init(manager: PatientManagerProtocol? = nil) {
        self.manager = manager ?? Container.shared.patientManager.resolve()
        self.profile = self.manager.turningProto
        self.positionDict = self.manager.cachePatient.positionToAvoid
    }
    
    // MARK: - Util
    func goNextBtnPress(completion: @escaping () -> Void) {
        var posToAvoid: [PositionalFlagCategory] = []
        for (position, isToggled) in positionDict {
            guard isToggled else { continue }
            posToAvoid.append(position)
        }
        
        if manager.isSessionInProgress {
            manager.updatePosToAvoid(Array(posToAvoid))
            completion()
        } else {
            manager.startSession(posToAvoid: Array(posToAvoid)) { result in
                switch result {
                case .success:
                    completion()
                case .failure(let error):
                    logger.error(error.localizedDescription)
                    self.alertMsg = error.localizedDescription
                    self.showAlert.toggle()
                }
            }
            manager.cachePatient.resetCache()
        }
    }
    
    func updatePositionsToAvoid(newPostionsToAvoid: [PositionalFlagCategory: Bool], completion: @escaping () -> Void) {
        var posToAvoid: Set<PositionalFlagCategory> = []
        for (position, isToggled) in newPostionsToAvoid {
            guard isToggled else { continue }
            posToAvoid.insert(position)
        }
        
        if manager.isSessionInProgress {
            manager.updatePosToAvoid(Array(posToAvoid))
            completion()
        }
    }
    
    func updateCache(positionToAvoid: PositionalFlagCategory, isOn: Bool) {
        manager.cachePatient.positionToAvoid.keys.forEach({
            manager.cachePatient.positionToAvoid[$0] = false
        })
        manager.cachePatient.positionToAvoid[positionToAvoid] = isOn
    }
    
    func resetCache() {
        manager.cachePatient.resetCache()
    }
}
