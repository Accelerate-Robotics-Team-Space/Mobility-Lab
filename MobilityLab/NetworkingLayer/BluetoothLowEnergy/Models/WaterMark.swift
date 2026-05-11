//
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

class WaterMark {
    var mark: Int64
    
    // MARK: - Init
    required init?(serialize data: Data) {
        guard let bigEndianData = data.to(type: Int64.self, from: 0) else { return nil }
        
        self.mark = Int64(bigEndian: bigEndianData)
    }

    init(mark: Int64) {
        self.mark = mark
    }
}

// MARK: - BleSerializable
extension WaterMark: Serializable {
    func toData() -> Data {
        var buffer = Data(capacity: 8)

        buffer.append(Data(from: self.mark.bigEndian))

        return buffer
    }
}
