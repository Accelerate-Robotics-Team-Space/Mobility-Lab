//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM

final class MockNotificationCenterService: NotificationCenterServiceProtocol {
    var removeObserverHandler: ((Any, NSNotification.Name?, Any?) -> Void)?
    var postHandler: ((NSNotification.Name, Any?, [AnyHashable: Any]?) -> Void)?
    var addObserverHandler: ((Any, Selector, NSNotification.Name?, Any?) -> Void)?

    func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        guard let removeObserverHandler else {
            fatalError("removeObserverHandler not set")
        }
        removeObserverHandler(observer, aName, anObject)
    }
    
    func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]?) {
        guard let postHandler else {
            fatalError("postHandler not set")
        }
        postHandler(aName, anObject, aUserInfo)
    }
    
    func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
        guard let addObserverHandler else {
            fatalError("addObserverHandler not set")
        }
        addObserverHandler(observer, aSelector, aName, anObject)
    }
}

final class NullNotificationCenterService: NotificationCenterServiceProtocol {
    func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        fatalError("Null Service Should Not Be Used")
    }

    func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]?) {
        fatalError("Null Service Should Not Be Used")
    }

    func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
        fatalError("Null Service Should Not Be Used")
    }
}
