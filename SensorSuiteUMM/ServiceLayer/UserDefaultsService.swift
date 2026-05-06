//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol UMMUserDefaultsServiceProtocol: UserDefaultsServiceProtocol {
    var unitMobilityMonitorGuid: String? { get set }

    /// Currently selected Unit Name. When not nil - UMM should show BMMs only from this Unit and ingore all others
    var selectedFilterUnitName: String? { get set }

    var useFrontCamera: Bool { get set }
}

extension Container {
    var userDefaults: Factory<UMMUserDefaultsServiceProtocol> {
        self { UserDefaultsService() }.cached
    }
}

final class UserDefaultsService: UMMUserDefaultsServiceProtocol {
    private var userDefaults: UserDefaults

    init(_ userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var lastCertificateRevocationListCheck: Date {
        get { userDefaults.lastCertificateRevocationListCheck }
        set { userDefaults.lastCertificateRevocationListCheck = newValue }
    }

    var baseStationGuid: String? {
        get { userDefaults.baseStationGuid }
        set { userDefaults.baseStationGuid = newValue }
    }

    var unitMobilityMonitorGuid: String? {
        get { userDefaults.unitMobilityMonitorGuid }
        set { userDefaults.unitMobilityMonitorGuid = newValue }
    }

    var deviceGuid: String? {
        get { unitMobilityMonitorGuid }
        set { unitMobilityMonitorGuid = newValue }
    }

    var facilityId: String? {
        get { userDefaults.facilityId }
        set { userDefaults.facilityId = newValue }
    }

    var facilityName: String? {
        get { userDefaults.facilityName }
        set { userDefaults.facilityName = newValue }
    }

    var peerIdKey: Int {
        get { userDefaults.peerIdKey }
        set { userDefaults.peerIdKey = newValue }
    }

    /// Currently selected Unit Name. When not nil - UMM should show BMMs only from this Unit and ingore all others
    var selectedFilterUnitName: String? {
        get { userDefaults.selectedFilterUnitName }
        set { userDefaults.selectedFilterUnitName = newValue }
    }

    var baseStationFromApple: String? {
        get { userDefaults.baseStationFromApple }
        set { userDefaults.baseStationFromApple = newValue }
    }

    var defaultingBaseStationFromApple: String {
        userDefaults.baseStationFromApple ?? UserDefaults.defaultBaseStationID
    }

    var useFrontCamera: Bool {
        get { userDefaults.useFrontCamera }
        set { userDefaults.useFrontCamera = newValue }
    }

    var host: String {
        get { userDefaults.host }
        set { userDefaults.host = newValue }
    }

    func reset() {
        userDefaults.reset()
    }

    var lastRunVersion: AppVersion? {
        get { AppVersion(userDefaults.string(forKey: UserDefaults.Keys.lastRunVersion.rawValue) ?? "?") }
        set { userDefaults.set(newValue?.rawString, forKey: UserDefaults.Keys.lastRunVersion.rawValue) }
    }

    func incrementPeerIDKey() -> Int {
        let currentPeerID = peerIdKey
        self.peerIdKey = currentPeerID + 1
        return currentPeerID + 1
    }
}
