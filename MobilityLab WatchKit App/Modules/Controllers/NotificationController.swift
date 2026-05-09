//
//  NotificationController.swift
//  MobilityLab WatchKit Extension
//
//  Created by Anton Vishnyak on 4/3/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI
import UserNotifications
import WatchKit

class NotificationController: WKUserNotificationHostingController<NotificationView> {
    override var body: NotificationView {
        return NotificationView()
    }

    override func didReceive(_ notification: UNNotification) {
        // This method is called when a notification needs to be presented.
        // Implement it if you use a dynamic notification interface.
        // Populate your dynamic notification interface as quickly as possible.
    }
}
