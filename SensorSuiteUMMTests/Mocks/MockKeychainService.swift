//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_UMM

final class MockKeychainService: KeychainServiceProtocol {
    init() { }

    var resetHandler: (() -> Void)?

    var devicePublicKey: SecKey?
    var deviceCertIdentity: SecIdentity?
    var deviceIntermediateCert: SecCertificate?
    var accessToken: String?
    var certificateSerialNumber: String?

    func reset() {
        guard let resetHandler else { fatalError("Reset Handler Must Be Set") }
        resetHandler()
    }
}

final class NullKeychainService: KeychainServiceProtocol {

    init() { }

    var devicePublicKey: SecKey? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var deviceCertIdentity: SecIdentity? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var deviceIntermediateCert: SecCertificate? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }
    
    var accessToken: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var certificateSerialNumber: String? {
        fatalError("Null Service Should Not Be Used")
    }

    func reset() {
        fatalError("Null Service Should Not Be Used")
    }
}
