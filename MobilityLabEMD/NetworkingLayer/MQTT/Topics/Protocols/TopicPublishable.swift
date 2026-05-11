//
//  TopicPublishable.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 12/28/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//
// Documentation: https://docs.oasis-open.org/mqtt/mqtt/v5.0/mqtt-v5.0.html

import Foundation

/// Protocol Designed to hold all the necessary information for publishing to a MQTT Server
protocol TopicPublishable {
    /// Specifies if the Will Message is to be retained when it is published.
    var isRetained: Bool { get }
    
    /// Delivers Messages according to the Quality of Service (QoS) levels defined by the enum
    var qualityOfService: DeliveryAssurance { get }
    
    /// Used to encode publish object to data to be send to BE via MQTT
    func toData() -> Data
}

extension TopicPublishable {
    /// Default Implementation of qualityOfService
    var qualityOfService: DeliveryAssurance {
        .atMostOnce
    }
}
