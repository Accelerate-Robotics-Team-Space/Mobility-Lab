//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

class ALTAction: Codable {
    let monitoring: Bool
    let pauseReason: PauseReason
    
    // MARK: - Init
    private init(monitoring: Bool, pauseReason: PauseReason) {
        self.monitoring = monitoring
        self.pauseReason = pauseReason
    }
}

enum PauseReason: String, Codable, CaseIterable {
    case pause = "Pause Monitoring"
    case swappingWearable = "Swapping Sensor"
    case swappingPatch = "Replacing Patch"
    case patientRequest = "Patient's Request"
    case caregiverRequest = "Caregiver's Request"
    case correctPatient = "Paused to correct patient"
    case sleep = "Sleep"
    case surgery = "Surgery/Procedure"
    case disconnected = "Sensor Disconnected"
    case endSession = "End Session"
    case crash = "BMM Disconnected"
    case null = "NULL"
	case physicalTherapy = "Physical therapy"
	case patientInChair = "Patient in chair"
	case outOfBedMobility = "Out of bed mobility"
}
