//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

@MainActor
final class PatientDetailsSystemDetailsCellViewModel: ObservableObject {
    @Injected(\.keychain) private var keychain
    @Injected(\.patientManager) private var patientManager
    @Injected(\.userDefaults) private var userDefaults

    var complianceAngle: String { userDefaults.complianceAngle!.readable }
    var turnProtocol: String { userDefaults.turnProtocol!.rawValue }
    var patient: String { patientManager.currentPatient?.altPatientId ?? "" }
    var deviceID: String { keychain.deviceId ?? "" }
}
