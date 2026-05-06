//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_UMM

final class MockUserDefaultsService: UMMUserDefaultsServiceProtocol {
    var resetHandler: (() -> Void)?
    var incrementHandler: (() -> Int)?

    var lastCertificateRevocationListCheck = Date()
    var baseStationGuid: String?
    var unitMobilityMonitorGuid: String?
    var facilityId: String?
    var facilityName: String?
    var peerIdKey: Int = 1
    var deviceGuid: String?
    var selectedFilterUnitName: String?
    var authToken: String?
    var baseStationFromApple: String?
    var useFrontCamera: Bool = false
    var defaultingBaseStationFromApple: String = UUID.null.uuidString
    var host: String = ""
    var lastRunVersion: AppVersion?

    func reset() {
        guard let resetHandler else { fatalError("Reset Handler Must Be Set") }
        resetHandler()
    }

    func incrementPeerIDKey() -> Int {
        guard let incrementHandler else {
            fatalError("incrementHandler must be set")
        }
        return incrementHandler()
    }
}

final class NullUserDefaultsService: UMMUserDefaultsServiceProtocol {
    init() { }

    var useFrontCamera: Bool {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var lastCertificateRevocationListCheck: Date {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var baseStationGuid: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var unitMobilityMonitorGuid: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var facilityId: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var facilityName: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var deviceGuid: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var peerIdKey: Int {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var selectedFilterUnitName: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var authToken: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var baseStationFromApple: String? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var defaultingBaseStationFromApple: String {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var host: String {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    var lastRunVersion: AppVersion? {
        get { fatalError("Null Service Should Not Be Used") }
        set { _ = newValue }
    }

    func reset() {
        fatalError("Null Service Should Not Be Used")
    }

    func incrementPeerIDKey() -> Int {
        fatalError("Null Service Should Not Be Used")
    }
}
