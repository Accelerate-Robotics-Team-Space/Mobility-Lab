//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation

class BaseUserDefaultsService: UserDefaultsServiceProtocol {
    let userDefaults: UserDefaults

    init(_ userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var lastCertificateRevocationListCheck: Date {
        get {
            let timeInterval = userDefaults.double(forKey: UserDefaults.Keys.lastCertificateRevocationListCheck.rawValue)
            return Date(timeIntervalSinceReferenceDate: timeInterval)
        }
        set {
            userDefaults.setValue(
                newValue.timeIntervalSinceReferenceDate,
                forKey: UserDefaults.Keys.lastCertificateRevocationListCheck.rawValue
            )
        }
    }

    var baseStationGuid: String? {
        get { userDefaults.string(forKey: UserDefaults.Keys.baseStationGuid.rawValue) }
        set { userDefaults.set(newValue, forKey: UserDefaults.Keys.baseStationGuid.rawValue) }
    }

    var facilityId: String? {
        get { userDefaults.string(forKey: UserDefaults.Keys.facilityGuuid.rawValue) }
        set { userDefaults.set(newValue, forKey: UserDefaults.Keys.facilityGuuid.rawValue) }
    }

    var facilityName: String? {
        get { userDefaults.string(forKey: UserDefaults.Keys.facilityName.rawValue) }
        set { userDefaults.set(newValue, forKey: UserDefaults.Keys.facilityName.rawValue) }
    }

    var peerIdKey: Int {
        get { userDefaults.integer(forKey: UserDefaults.Keys.peerIdKey.rawValue) }
        set { userDefaults.set(newValue, forKey: UserDefaults.Keys.peerIdKey.rawValue) }
    }

    func incrementPeerIDKey() -> Int {
        var peerIdValue = self.peerIdKey
        peerIdValue += 1
        self.peerIdKey = peerIdValue
        return peerIdValue
    }

    var baseStationFromApple: String? {
        get { userDefaults.string(forKey: UserDefaults.Keys.baseStationFromApple.rawValue) }
        set { userDefaults.set(newValue, forKey: UserDefaults.Keys.baseStationFromApple.rawValue) }
    }

    var defaultingBaseStationFromApple: String {
        userDefaults.string(forKey: UserDefaults.Keys.baseStationFromApple.rawValue) ?? UserDefaults.defaultBaseStationID
    }

    var host: String {
        get { userDefaults.string(forKey: UserDefaults.Keys.host.rawValue) ?? "" }
        set { userDefaults.set(newValue, forKey: UserDefaults.Keys.host.rawValue) }
    }

    func reset() {
        let dict = userDefaults.dictionaryRepresentation()
        dict.keys.forEach({ userDefaults.removeObject(forKey: $0) })
    }

    var deviceGuid: String? {
        get { fatalError("Base Class must be subclassed and this property overridden") }
        set { _ = newValue; fatalError("Base Class must be subclassed and this property overridden") }
    }

    var lastRunVersion: AppVersion? {
        get { AppVersion(userDefaults.string(forKey: UserDefaults.Keys.lastRunVersion.rawValue) ?? "?") }
        set { userDefaults.set(newValue?.rawString, forKey: UserDefaults.Keys.lastRunVersion.rawValue) }
    }
}

extension UserDefaults {
    static let defaultBaseStationID: String = UUID.null.uuidString
}
