//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

@MainActor
final class AtlasLogoPadderViewModel: ObservableObject {

    @Injected(\.patientManager) private var patientManager
    @Injected(\.mqttService) private var mqttService

    func didTapLogo() {
        patientManager.resetRouter()
        mqttService.reset()
        mqttService.connect()
    }

}
