//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

struct StartEndSessionModel: Codable, Serializable {
	var baseStationId: String
	var facilityId: String
	var patientDetails: PublishablePatient
	
	enum CodingKeys: String, CodingKey {
		case baseStationId = "BaseStationId"
		case facilityId = "FacilityId"
		case patientDetails = "PatientSessionVm"
	}
}
