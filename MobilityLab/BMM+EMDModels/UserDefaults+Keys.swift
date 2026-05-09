//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum Keys: String {
        // Common
        case lastCertificateRevocationListCheck = "Last-Certificate-Revocation-List-Check"
        case peerIdKey = "Peer-To-Peer-Identifier-Key"
        case baseStationGuid = "Base-Station-Globally-Unique-Identifier"
        case baseStationFromApple = "Base-Station-From-Apple"
        case facilityGuuid = "Facility-Globally-Unique-Identifier"
        case facilityName = "Facility-Name"
        case rearCamera = "RearCamera"
        case host = "network-host"

        case turnProtocol = "Turn-Protocol"
        case complianceAngle = "Compliance-Angle"
        case isComplianceEnabled = "Is-Compliance-Customization-Enabled"
        case isTurnProtocolEnabled = "Is-Turn-Protocol-Customization-Enabled"
        case registrationTime = "Registration-Time"
        case lastRunVersion

        #if EMD
        case filterUnitName = "Filter-Unit-Name"
        case unitMobilityMonitorGuid = "Unit-Mobility-Monitor-Globally-Unique-Identifier"
        #elseif BMM
        case unsyncedPatchCount = "Patch-Count-To-Be-Synced"
        #endif
    }
}
