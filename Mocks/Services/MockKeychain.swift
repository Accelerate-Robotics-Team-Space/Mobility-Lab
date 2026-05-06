//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockKeychain: KeychainProtocol {
    var resetHandler: (() -> Void)?

    var deviceCertIdentity: SecIdentity?
    
    var deviceIntermediateCert: SecCertificate?
    
    var devicePublicKey: SecKey?
    
    var deviceId: String?
    
    var accessToken: String?
    
    var deviceCertificate: SecCertificate?

    var certificateSerialNumber: String?

    func reset() {
        guard let resetHandler else {
            fatalError("reset handler must be set")
        }
        resetHandler()
    }
}

final class NullKeychain: KeychainProtocol {
    var deviceCertIdentity: SecIdentity? {
        get { fatalError("Null Service Should Not be Called") }
        set { _ = newValue; fatalError("Null Service Should Not be Called") }
    }

    var deviceIntermediateCert: SecCertificate? {
        get { fatalError("Null Service Should Not be Called") }
        set { _ = newValue; fatalError("Null Service Should Not be Called") }
    }

    var devicePublicKey: SecKey? {
        get { fatalError("Null Service Should Not be Called") }
        set { _ = newValue; fatalError("Null Service Should Not be Called") }
    }

    var deviceId: String? {
        get { fatalError("Null Service Should Not be Called") }
        set { _ = newValue; fatalError("Null Service Should Not be Called") }
    }

    var accessToken: String? {
        get { fatalError("Null Service Should Not be Called") }
        set { _ = newValue; fatalError("Null Service Should Not be Called") }
    }

    var deviceCertificate: SecCertificate? {
        get { fatalError("Null Service Should Not be Called") }
        set { _ = newValue; fatalError("Null Service Should Not be Called") }
    }

    var certificateSerialNumber: String? {
        fatalError("Null Service Should Not be Called")
    }

    func reset() {
        fatalError("Null Service Should Not be Called")
    }
}
