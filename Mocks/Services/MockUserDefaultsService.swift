//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockUserDefaultsService: BMMUserDefaultsServiceProtocol {
    var turnProtocol: TurnProtocol?
    var complianceAngle: ComplianceAngle?
    var isComplianceEnabled: Bool = false
    var isTurnProtocolEnabled: Bool = false
    var unsyncedPatchCount: Int = 0
    var deviceRegistrationTime: String?
    var lastCertificateRevocationListCheck = Date(timeIntervalSinceReferenceDate: 0)
    var baseStationGuid: String?
    var deviceGuid: String?
    var facilityId: String?
    var facilityName: String?
    var peerIdKey: Int = 0
    var baseStationFromApple: String?
    var defaultingBaseStationFromApple: String = UUID.null.uuidString
    var host: String = ""
    var lastRunVersion: AppVersion?

    var resetHandler: (() -> Void)?
    var incrementPeerIDHandler: (() -> Int)?

    func reset() {
        guard let resetHandler else {
            fatalError("resetHandler must be set")
        }
        resetHandler()
    }

    func incrementPeerIDKey() -> Int {
        guard let incrementPeerIDHandler else {
            fatalError("incrementPeerIDHandler must be set")
        }
        return incrementPeerIDHandler()
    }
}

final class NullUserDefaultsService: BMMUserDefaultsServiceProtocol {
    var turnProtocol: TurnProtocol? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var complianceAngle: ComplianceAngle? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var isComplianceEnabled: Bool {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var isTurnProtocolEnabled: Bool {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var unsyncedPatchCount: Int {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var deviceRegistrationTime: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var lastCertificateRevocationListCheck: Date {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var baseStationGuid: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var deviceGuid: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var facilityId: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var facilityName: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var peerIdKey: Int {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var baseStationFromApple: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var defaultingBaseStationFromApple: String {
        fatalError("Null Service Should Not Be Used")
    }

    var host: String {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    var lastRunVersion: AppVersion? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue; fatalError("Null Service Should Not Be Used") }
    }

    func reset() {
        fatalError("Null Service Should Not Be Used")
    }

    func incrementPeerIDKey() -> Int {
        fatalError("Null Service Should Not Be Used")
    }
}
