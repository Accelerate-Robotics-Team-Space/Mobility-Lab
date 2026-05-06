// swiftlint:disable:this file_name
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

@testable import SensorSuite_BMM
import XCTest

final class _EnvironmentTests: XCTestCase {
    func testIsRunningOnSimulator() {
        #if targetEnvironment(simulator)
        XCTAssertTrue(true)
        #else
        XCTFail("Tests Should Be Run On Simulator Only")
        #endif
    }
}
