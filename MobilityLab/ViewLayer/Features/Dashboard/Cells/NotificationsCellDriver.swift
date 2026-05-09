//
//  NotificationsCellDriver.swift
//  MobilityLab
//
//  Created by Josh Franco on 3/3/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

class NotificationsCellDriver: ObservableObject {
    @Published var notifications: [ALTNotification]

    private let patientManager: PatientManagerProtocol

    // MARK: - Init
    init(using manager: PatientManagerProtocol? = nil) {
        self.patientManager = manager ?? Container.shared.patientManager.resolve()
        self.notifications = patientManager.session?.notificationsArr ?? []
        patientManager.session?.notificationDelegate = self
    }
}

// MARK: - SessionNotificationDelegate
extension NotificationsCellDriver: SessionNotificationDelegate {
    func notificationsUpdated(_ notifications: [ALTNotification]) {
        self.notifications = notifications
    }
}
