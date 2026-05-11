//
//  DeliveryAssurance.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 12/28/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//
// Documentation: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901234

/// MQTT delivers Messages according to the Quality of Service (QoS) levels defined in the following cases.
enum DeliveryAssurance: Int, Codable {
    /// The message is delivered according to the capabilities of the underlying network.
    /// No response is sent by the receiver and no retry is performed by the sender.
    /// The message arrives at the receiver either once or not at all.
    case atMostOnce = 0
    
    /// This Quality of Service level ensures that the message arrives at the receiver at least once.
    case atLeastOnce = 1
    
    /// This is the highest Quality of Service level, for use when neither loss nor duplication of messages are acceptable.
    case exactlyOnce = 2
    
    var qosLvl: MQTTQosLevel {
        switch self {
        case .atMostOnce:
            return .atMostOnce
        case .atLeastOnce:
            return .atLeastOnce
        case .exactlyOnce:
            return .exactlyOnce
        }
    }
}
