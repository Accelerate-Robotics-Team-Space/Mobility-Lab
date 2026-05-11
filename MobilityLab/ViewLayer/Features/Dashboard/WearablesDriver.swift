//
//  WearablesDriver.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 11/8/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import Foundation

final class WearablesDriver: ObservableObject {
    @Published var modal: WearablesActiveModal?
    @Published var wearable: Wearable?
    
    enum WearablesActiveModal: Identifiable {
        case popup
        
        var id: Int {
            hashValue
        }
    }
}
