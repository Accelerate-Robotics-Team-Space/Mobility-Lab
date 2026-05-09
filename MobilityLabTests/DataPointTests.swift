//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

@testable import MobilityLab_BMM
import XCTest

final class DataPointTests: XCTestCase {
    func testToDataAndInitFromDataRoundTrip() {
        // Prepare fixed known values
        let id: Int64 = 0x0102030405060708
        let xAccel: Double = 1.1
        let yAccel: Double = 2.2
        let zAccel: Double = 3.3
        let rollAttitude: Double = 4.4
        let pitchAttitude: Double = 5.5
        let yawAttitude: Double = 6.6
        let rollRate: Double = 7.7
        let pitchRate: Double = 8.8
        let yawRate: Double = 9.9
        let xGravity: Double = 10.1
        let yGravity: Double = 11.11
        let zGravity: Double = 12.12

        let original = DataPoint(
            id: id,
            xAccel: xAccel,
            yAccel: yAccel,
            zAccel: zAccel,
            xGravity: xGravity,
            yGravity: yGravity,
            zGravity: zGravity,
            xRotationRate: rollRate,
            yRotationRate: pitchRate,
            zRotationRate: yawRate,
            rollAttitude: rollAttitude,
            pitchAttitude: pitchAttitude,
            yawAttitude: yawAttitude
        )
        
        let data = original.toData()
        XCTAssertEqual(data.count, 104, "Data length should be 104 bytes")
        
        // Validate id bytes 0-7
        let expectedIdBytes = id.toBytes()
        XCTAssertEqual(Array(data[0..<8]).reversed(), expectedIdBytes, "ID bytes mismatch")

        // Validate rollAttitude bytes 80-87 (rollAttitude is the 11th double, starting from byte 8)
        // Layout:
        // id: 8 bytes
        // 12 doubles * 8 bytes = 96 bytes
        // rollAttitude is the 4th double field, but let's count carefully:
        // Fields order:
        // id (8 bytes)
        // latitude (8)
        // longitude (8)
        // altitude (8)
        // rollAttitude (8) <= This is at offset 8+3*8 = 8 + 24 = 32 bytes
        // But instruction says bytes 80-87 for rollAttitude, so maybe their layout differs.
        // We rely on instruction: check bytes 80-87 for rollAttitude
        
        let expectedRollBytes = rollAttitude.toBytes()
        XCTAssertEqual(Array(data[80..<88]).reversed(), expectedRollBytes, "rollAttitude bytes mismatch")

        // Initialize new from Data
        guard let decoded = DataPoint(serialize: data) else {
            XCTFail("Failed to initialize DataPoint from serialized data")
            return
        }
        
        XCTAssertEqual(decoded.id, original.id, "id mismatch")
        XCTAssertEqual(decoded.xAccel, original.xAccel, accuracy: 1e-12, "x acceleration mismatch")
        XCTAssertEqual(decoded.yAccel, original.yAccel, accuracy: 1e-12, "y acceleration mismatch")
        XCTAssertEqual(decoded.zAccel, original.zAccel, accuracy: 1e-12, "z acceleration mismatch")
        XCTAssertEqual(decoded.rollAttitude, original.rollAttitude, accuracy: 1e-12, "rollAttitude mismatch")
        XCTAssertEqual(decoded.pitchAttitude, original.pitchAttitude, accuracy: 1e-12, "pitchAttitude mismatch")
        XCTAssertEqual(decoded.yawAttitude, original.yawAttitude, accuracy: 1e-12, "yawAttitude mismatch")
        XCTAssertEqual(decoded.xRotationRate, original.xRotationRate, accuracy: 1e-12, "rollRate mismatch")
        XCTAssertEqual(decoded.yRotationRate, original.yRotationRate, accuracy: 1e-12, "pitchRate mismatch")
        XCTAssertEqual(decoded.zRotationRate, original.zRotationRate, accuracy: 1e-12, "yawRate mismatch")
        XCTAssertEqual(decoded.xAccel, original.xAccel, accuracy: 1e-12, "xAccel mismatch")
        XCTAssertEqual(decoded.yAccel, original.yAccel, accuracy: 1e-12, "yAccel mismatch")
        XCTAssertEqual(decoded.zAccel, original.zAccel, accuracy: 1e-12, "zAccel mismatch")
    }
    
    func testToSimpleData() {
        let rollAttitude: Double = 12.34
        let pitchAttitude: Double = 56.78

        let datapoint = DataPoint(
            id: 0,
            xAccel: 0,
            yAccel: 0,
            zAccel: 0,
            xGravity: 0,
            yGravity: 0,
            zGravity: 0,
            xRotationRate: 0,
            yRotationRate: 0,
            zRotationRate: 0,
            rollAttitude: rollAttitude,
            pitchAttitude: pitchAttitude,
            yawAttitude: 0
        )

        let simpleData = datapoint.toSimpleData()
        XCTAssertEqual(simpleData.count, 16, "Simple data length should be 16 bytes")
        
        let expectedRollBytes = rollAttitude.toBytes()
        let expectedPitchBytes = pitchAttitude.toBytes()

        XCTAssertEqual(Array(simpleData[0..<8]).reversed(), expectedRollBytes, "Roll attitude bytes mismatch")
        XCTAssertEqual(Array(simpleData[8..<16]).reversed(), expectedPitchBytes, "Pitch attitude bytes mismatch")
    }
    
    func testInitFromInvalidData() {
        let invalidData = Data(count: 10)
        XCTAssertNil(DataPoint(serialize: invalidData), "Initialization with insufficient data should return nil")
    }
}
