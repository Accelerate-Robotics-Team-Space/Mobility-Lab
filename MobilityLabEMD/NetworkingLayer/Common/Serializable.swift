//
//  Serializable.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
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
            // TODO: Do this Decoding in a service where the dateDecodingStrategy can be set, 
            // rather than in an extension where it cannot easily be tested
            let registration = try JSONDecoder().decode(Self.self, from: data)
            self = registration
        } catch {
			logger.error(error.localizedDescription)
            return nil
        }
    }
    
    func toData() -> Data {
        do {
            // TODO: Do this Encoding in a service where the dateEncodingStrategy can be set, 
            // rather than in an extension where it cannot easily be tested
            return try JSONEncoder().encode(self)
        } catch {
            logger.warn("Serializable Encoder Err: \(error.localizedDescription)")
            return Data()
        }
    }
}
