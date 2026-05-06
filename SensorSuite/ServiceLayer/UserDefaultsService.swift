//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol BMMUserDefaultsServiceProtocol: UserDefaultsServiceProtocol {
    var turnProtocol: TurnProtocol? { get set }
    var complianceAngle: ComplianceAngle? { get set }
    var isComplianceEnabled: Bool { get set }
    var isTurnProtocolEnabled: Bool { get set }
    var unsyncedPatchCount: Int { get set }
    var deviceRegistrationTime: String? { get set }
}

extension Container {
    var userDefaults: Factory<BMMUserDefaultsServiceProtocol> {
        self { UserDefaultsService() }.cached
    }
}

final class UserDefaultsService: BaseUserDefaultsService, BMMUserDefaultsServiceProtocol {
    override var deviceGuid: String? {
        get { baseStationGuid }
        set { baseStationGuid = newValue }
    }

    var turnProtocol: TurnProtocol? {
        get { TurnProtocol(rawValue: userDefaults.string(forKey: UserDefaults.Keys.turnProtocol.rawValue) ?? "") ?? .Q2 }
        set { userDefaults.set(newValue?.rawValue, forKey: UserDefaults.Keys.turnProtocol.rawValue) }
    }

    var complianceAngle: ComplianceAngle? {
        get { ComplianceAngle(rawValue: userDefaults.string(forKey: UserDefaults.Keys.complianceAngle.rawValue) ?? "") ?? .angle20 }
        set { userDefaults.set(newValue?.rawValue, forKey: UserDefaults.Keys.complianceAngle.rawValue) }
    }

    var isComplianceEnabled: Bool {
        get { userDefaults.bool(forKey: UserDefaults.Keys.isComplianceEnabled.rawValue) }
        set { userDefaults.set(newValue, forKey: UserDefaults.Keys.isComplianceEnabled.rawValue) }
    }

    var isTurnProtocolEnabled: Bool {
        get { userDefaults.bool(forKey: UserDefaults.Keys.isTurnProtocolEnabled.rawValue) }
        set { userDefaults.set(newValue, forKey: UserDefaults.Keys.isTurnProtocolEnabled.rawValue) }
    }

    var unsyncedPatchCount: Int {
        get { userDefaults.integer(forKey: UserDefaults.Keys.unsyncedPatchCount.rawValue) }
        set { userDefaults.set(newValue, forKey: UserDefaults.Keys.unsyncedPatchCount.rawValue) }
    }

    var deviceRegistrationTime: String? {
        get { userDefaults.string(forKey: UserDefaults.Keys.registrationTime.rawValue) }
        set { userDefaults.set(newValue, forKey: UserDefaults.Keys.registrationTime.rawValue) }
    }
}
