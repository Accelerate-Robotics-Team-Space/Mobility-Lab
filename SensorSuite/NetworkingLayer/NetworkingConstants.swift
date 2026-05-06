//
//  NetworkingConstants.swift
//  SensorSuite
//
//  Created by Josh Franco on 7/31/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

struct NetworkingConstants {
    static func baseUrlStr(host: String) -> String {
        "https://" + host + "/"
    }
    
    // MARK: - MQTT
    static let showMQTTLogs = true
    static let mqttPort: Int = 443
    static let mqttTls = true
    static let mqttPath = "/mqtt"
}
