//
//  NetworkingConstants.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

struct NetworkingConstants {
    static var baseUrlStr: String {
        "https://" + UserDefaults.standard.host + "/"
    }
    
    // MARK: - MQTT
    static let showMQTTLogs = true
    static var mqttHost: String {
        UserDefaults.standard.host
    }
    static let mqttPort: Int = 443
    static let mqttTls = true
    static let mqttPath = "/mqtt"
}
