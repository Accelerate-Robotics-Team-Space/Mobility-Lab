//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

// Wrapper for PatientMonitorDriver to limit publishing changes to DashboardView
// The underlying (non-published) instance is exposed for injecting into child-views
final class PatientMonitorWrapper: ObservableObject {

    @Published private var patientMonitorDriver: PatientMonitorDriver

    @Published var alertQueue: [PatientAlert] = []
    @Published var isMonitoring: Bool = false
    @Binding var isTrackingStr: String

    private var cancellables: Set<AnyCancellable> = []

    init(_ patientMonitorDriver: PatientMonitorDriver, isPreview: Bool = false) {
        self.patientMonitorDriver = patientMonitorDriver

        _isTrackingStr = .init(
            get: { patientMonitorDriver.isTrackingStr },
            set: { patientMonitorDriver.isTrackingStr = $0 }
        )

        patientMonitorDriver
            .$alertQueue
            .sink { [weak self] queue in
                self?.alertQueue = queue
            }
            .store(in: &cancellables)

        patientMonitorDriver
            .$currentState
            .sink { [weak self] state in
                self?.isMonitoring = state != .onStart
            }
            .store(in: &cancellables)

        if isPreview {
            self.patientMonitorDriver.isWearableConnected = true
            self.patientMonitorDriver.desiredPosition = .right
            self.patientMonitorDriver.actualPosition = .right
        }
    }

    var driver: PatientMonitorDriver {
        patientMonitorDriver
    }

    func setIsWearableConnected(_ connected: Bool) {
        patientMonitorDriver.isWearableConnected = connected
    }

    func setDesiredPosition(_ position: PositionalFlagCategory) {
        patientMonitorDriver.desiredPosition = position
    }

    func setActualPosition(_ position: PositionalFlagCategory) {
        patientMonitorDriver.actualPosition = position
    }
}
