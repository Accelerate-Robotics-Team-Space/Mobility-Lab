//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

// MARK: - EMD User Defaults
extension UserDefaults {
    var deviceGuid: String? {
        get { unitMobilityMonitorGuid }
        set { unitMobilityMonitorGuid = newValue }
    }

    var unitMobilityMonitorGuid: String? {
        get { string(forKey: Keys.unitMobilityMonitorGuid.rawValue) }
        set { set(newValue, forKey: Keys.unitMobilityMonitorGuid.rawValue) }
    }

    /// Currently selected Unit Name. When not nil - EMD should show BMMs only from this Unit and ingore all others
    var selectedFilterUnitName: String? {
        get { string(forKey: Keys.filterUnitName.rawValue) }
        set { set(newValue, forKey: Keys.filterUnitName.rawValue) }
    }

    var useFrontCamera: Bool {
        get { !bool(forKey: Keys.rearCamera.rawValue) }
        set { set(!newValue, forKey: Keys.rearCamera.rawValue) }
    }
    
    // MARK: - Util
    
    var turnProtocol: TurnProtocol {
        get {
            TurnProtocol(rawValue: UserDefaults.standard.string(forKey: Keys.turnProtocol.rawValue) ?? "") ?? .Q2
        } set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.turnProtocol.rawValue)
        }
    }

    var complianceAngle: ComplianceAngle? {
        get {
            ComplianceAngle(rawValue: UserDefaults.standard.string(forKey: Keys.complianceAngle.rawValue) ?? "") ?? .angle20
        } set {
            UserDefaults.standard.set(newValue?.rawValue, forKey: Keys.complianceAngle.rawValue)
        }
    }

    var isComplianceEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.isComplianceEnabled.rawValue)
        } set {
            UserDefaults.standard.set(newValue, forKey: Keys.isComplianceEnabled.rawValue)
        }
    }

    var isTurnProtocolEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.isTurnProtocolEnabled.rawValue)
        } set {
            UserDefaults.standard.set(newValue, forKey: Keys.isTurnProtocolEnabled.rawValue)
        }
    }
}

extension UserDefaults {
    var lastCertificateRevocationListCheck: Date {
        get {
            let timeInterval = double(forKey: Keys.lastCertificateRevocationListCheck.rawValue)
            return Date(timeIntervalSinceReferenceDate: timeInterval)
        }
        set {
            setValue(
                newValue.timeIntervalSinceReferenceDate,
                forKey: Keys.lastCertificateRevocationListCheck.rawValue
            )
        }
    }

    var peerIdKey: Int {
        get { integer(forKey: Keys.peerIdKey.rawValue) }
        set { set(newValue, forKey: Keys.peerIdKey.rawValue) }
    }

    var baseStationFromApple: String? {
        get { string(forKey: Keys.baseStationFromApple.rawValue) }
        set { set(newValue, forKey: Keys.baseStationFromApple.rawValue) }
    }

    var defaultingBaseStationFromApple: String {
        string(forKey: Keys.baseStationFromApple.rawValue) ?? UserDefaults.defaultBaseStationID
    }

    var deviceRegistrationTime: String? {
        get { string(forKey: Keys.registrationTime.rawValue) }
        set { set(newValue, forKey: Keys.registrationTime.rawValue) }
    }

    func reset() {
        let dict = dictionaryRepresentation()
        dict.keys.forEach({ self.removeObject(forKey: $0) })
    }

    var baseStationGuid: String? {
        get { string(forKey: Keys.baseStationGuid.rawValue) }
        set { set(newValue, forKey: Keys.baseStationGuid.rawValue) }
    }

    var host: String {
        get { string(forKey: Keys.host.rawValue) ?? "" }
        set { set(newValue, forKey: Keys.host.rawValue) }
    }

    var facilityId: String? {
        get { string(forKey: Keys.facilityGuuid.rawValue) }
        set { set(newValue, forKey: Keys.facilityGuuid.rawValue) }
    }

    var facilityName: String? {
        get { string(forKey: Keys.facilityName.rawValue) }
        set { set(newValue, forKey: Keys.facilityName.rawValue) }
    }
}
