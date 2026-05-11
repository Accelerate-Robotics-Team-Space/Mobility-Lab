//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation
@testable import MobilityLab_EMD

final class MockNotificationService: NotificationServiceProtocol {
    var postHandler: ((NotificationService.Key) -> Void)?
    var observePublisherHandler: ((NotificationService.Key) -> AnyPublisher<[AnyHashable: Any]?, Never>)?
    var observeHandler: ((NotificationService.Key) -> [AnyHashable: Any]?)?

    init() { }

    func post(_ key: NotificationService.Key) {
        guard let postHandler else { fatalError("Post Handler Must Be Set") }
        postHandler(key)
    }

    func observePublisher(_ key: NotificationService.Key) -> AnyPublisher<[AnyHashable: Any]?, Never> {
        guard let observePublisherHandler else { fatalError("Observe Publisher Handler Must Be Set") }
        return observePublisherHandler(key)
    }

    func observe(_ key: NotificationService.Key, closure: @escaping (([AnyHashable: Any]?) -> Void)) {
        guard let observeHandler else { fatalError("Observe Handler Must Be Set") }
        closure(observeHandler(key))
    }
}

final class NullNotificationService: NotificationServiceProtocol {
    init() { }

    func post(_ key: NotificationService.Key) {
        fatalError("Null Service Should Not Be Used")
    }

    func observePublisher(_ key: NotificationService.Key) -> AnyPublisher<[AnyHashable: Any]?, Never> {
        fatalError("Null Service Should Not Be Used")
    }

    func observe(_ key: NotificationService.Key, closure: @escaping (([AnyHashable: Any]?) -> Void)) {
        fatalError("Null Service Should Not Be Used")
    }
}
