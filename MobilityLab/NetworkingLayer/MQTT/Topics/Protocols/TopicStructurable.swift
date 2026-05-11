//
//  TopicStructurable.swift
//  MobilityLab
//
//  Created by Josh Franco on 8/3/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//
// Documentation: https://docs.oasis-open.org/mqtt/mqtt/v5.0/mqtt-v5.0.html

import Foundation

/// Protocol Designed to hold all the necessary information for both publishing and subscribing to a MQTT Server
protocol TopicStructurable: Hashable {
    associatedtype Publisher: TopicPublishable
    
    var structPrefixSuffix: (String, String) { get }
    
    /// Structure that is used to subscribe to a specific topic on the BE via MQTT (Must correspond to structure in the Publisher)
    var structure: String { get }
    
    /// Quality of service for the subscription (defaults to atMostOnce)
    var qualityOfService: MQTTQosLevel { get }

    /// Defines how to decode a result to a subscription based on the topic
    /// - Parameter data: The data to be decoded
    func decodeResult(_ data: Data) -> Publisher?
}

extension TopicStructurable {
    /// Default Implementation of qualityOfService
    var qualityOfService: MQTTQosLevel {
        .atMostOnce
    }
    
    var simplifyStruct: String {
        let (prefix, suffix) = structPrefixSuffix
        return "\(prefix)/.../\(suffix)"
    }
}
