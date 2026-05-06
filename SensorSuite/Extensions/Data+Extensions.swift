//
//  Data+Extensions.swift
//  SensorSuite
//
//  Created by Anton Vishnyak on 4/10/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Data {
    /// Create a data buffer from a value type
    ///
    /// - Warning: Only works with simple types such as Int or Double
    /// - Parameter value: A value type
    init<T>(from value: T) {
        self = Swift.withUnsafeBytes(of: value) { Data($0) }
    }

    /// Parse data buffer into a given type
    ///
    /// - Warning: Only works with simple types such as Int or Double
    /// - Parameter type: Type.self
    /// - Returns: Data as type
    func to<T>(type: T.Type) -> T? where T: ExpressibleByIntegerLiteral {
        var value: T = 0

        guard count >= MemoryLayout.size(ofValue: value) else { return nil }

        _ = Swift.withUnsafeMutableBytes(of: &value) { copyBytes(to: $0) }

        return value
    }

    /// Parse data buffer into a given type
    ///
    /// - Warning: Only works with simple types such as Int or Double
    /// - Parameter type: Type.self
    /// - Returns: Data as type
    func to<T>(type: T.Type, from: Int) -> T? where T: ExpressibleByIntegerLiteral {
        var value: T = 0

        let range: Range = from..<(from + MemoryLayout.size(ofValue: value))

        guard count >= range.endIndex else { return nil }

        _ = Swift.withUnsafeMutableBytes(of: &value) { copyBytes(to: $0, from: range) }

        return value
    }
    
    func asDataChunks(chunkSize: Int) -> [Data] {
        let dataLen = (self as NSData).length
        let fullChunks = Int(dataLen / chunkSize)
        let totalChunks = fullChunks + (dataLen % chunkSize != 0 ? 1 : 0)

        var chunks = [Data]()
        for chunkCounter in 0..<totalChunks {
            var chunk = Data(capacity: chunkSize + 1)
            let chunkBase = chunkCounter * chunkSize
            var diff = chunkSize

            if chunkCounter == totalChunks - 1 {
                diff = dataLen - chunkBase
            }

            chunk.append(BLESequence.packet.rawValue.bigEndian)
            chunk.append(self.subdata(in: chunkBase..<(chunkBase + diff)))

            chunks.append(chunk)
        }

        return chunks
    }
    
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }

    func prettyJSON() -> NSString? {
        guard let encoded = try? JSONSerialization.jsonObject(with: self),
              let prettyJSONData = try? JSONSerialization.data(withJSONObject: encoded, options: [.prettyPrinted, .sortedKeys]),
              let jsonString = NSString(data: prettyJSONData, encoding: NSUTF8StringEncoding) else {
            return NSString(data: self, encoding: NSUTF8StringEncoding)
        }
        return jsonString
    }
}
