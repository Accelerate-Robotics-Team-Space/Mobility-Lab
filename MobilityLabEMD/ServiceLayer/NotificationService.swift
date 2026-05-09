//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation

protocol NotificationServiceProtocol {
    func post(_ key: NotificationService.Key)
    func observePublisher(_ key: NotificationService.Key) -> AnyPublisher<[AnyHashable: Any]?, Never>
    func observe(_ key: NotificationService.Key, closure: @escaping (([AnyHashable: Any]?) -> Void))
}

extension Container {
    var notification: Factory<NotificationServiceProtocol> {
        self { NotificationService() }.cached
    }
}

final class NotificationService: NotificationServiceProtocol {

    enum Key: String {
        case revokedNote = "Device-Registration-Revoked"

        init?(from name: Notification.Name) {
            self.init(rawValue: name.rawValue)
        }
    }

    private var publishers: [Key: CurrentValueSubject<[AnyHashable: Any]?, Never>] = [:]
    private var cancellables: [AnyCancellable] = []

    var notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    func post(_ key: Key) {
        let name = Notification.Name(key.rawValue)
        notificationCenter.post(name: name, object: nil)
    }

    func observePublisher(_ key: Key) -> AnyPublisher<[AnyHashable: Any]?, Never> {
        let currentValueSubject: CurrentValueSubject<[AnyHashable: Any]?, Never> = .init(nil)
        publishers[key] = currentValueSubject
        notificationCenter.addObserver(self, selector: #selector(handleObservation(notification:)), name: key.name, object: nil)
        return currentValueSubject.eraseToAnyPublisher()
    }

    func observe(_ key: Key, closure: @escaping (([AnyHashable: Any]?) -> Void)) {
        let publisher = observePublisher(key)
        publisher.sink {
            closure($0)
        }
        .store(in: &cancellables)
    }
}

private extension NotificationService {
    @objc
    func handleObservation(notification: Notification) {
        if let key = Key(from: notification.name),
           let publisher = publishers[key] {
            publisher.send(notification.userInfo)
        }
    }
}

extension NotificationService.Key {
    var name: Notification.Name {
        Notification.Name(self.rawValue)
    }
}
