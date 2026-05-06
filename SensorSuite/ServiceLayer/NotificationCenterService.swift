//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol NotificationCenterServiceProtocol: AnyObject {
    func post(name aName: NSNotification.Name, object anObject: Any?)
    func post(name aName: NSNotification.Name, userInfo aUserInfo: [AnyHashable: Any]?)
    func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]?)
    func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?)
    func removeObserver(_ observer: Any)
    func removeObserver(_ observer: Any, name aName: NSNotification.Name?)
    func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?)
}

extension Container {
    var notificationCenter: Factory<NotificationCenterServiceProtocol> {
        self { NotificationCenterService.shared }.cached
    }
}

extension NotificationCenterServiceProtocol {
    func post(name aName: NSNotification.Name, object anObject: Any? = nil) {
        post(name: aName, object: anObject, userInfo: nil)
    }

    func post(name aName: NSNotification.Name, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        post(name: aName, object: nil, userInfo: aUserInfo)
    }

    func removeObserver(_ observer: Any, name aName: NSNotification.Name? = nil) {
        self.removeObserver(observer, name: aName, object: nil)
    }

    func removeObserver(_ observer: Any) {
        self.removeObserver(observer, name: nil, object: nil)
    }
}

final class NotificationCenterService: NotificationCenterServiceProtocol {
    static let shared: NotificationCenterServiceProtocol = NotificationCenterService()

    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        notificationCenter.post(name: aName, object: anObject, userInfo: aUserInfo)
    }

    func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
        notificationCenter.addObserver(observer, selector: aSelector, name: aName, object: anObject)
    }

    func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        notificationCenter.removeObserver(observer, name: aName, object: anObject)
    }
}
