//
//  Serializable.swift
//  MobilityLab
//
//  Created by Josh Franco on 8/31/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

/// Protocol that is used by the BLE packet serializer
protocol Serializable {
    func toData() -> Data
    init?(serialize data: Data)
}

extension Serializable where Self: Codable {
    init?(serialize data: Data) {
        do {
            let registration = try JSONDecoder().decode(Self.self, from: data)
            self = registration
        } catch {
            logger.warn("Serializable Decoder Err: \(error.localizedDescription)")
            return nil
        }
    }
    
    func toData() -> Data {
        do {
            return try JSONEncoder().encode(self)
        } catch {
            logger.warn("Serializable Encoder Err: \(error.localizedDescription)")
            return Data()
        }
    }
}
