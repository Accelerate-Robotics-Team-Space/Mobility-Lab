//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import Dispatch

final class StaticStorageValuePublisher<Output>: StorageValuePublisher<Output> {
    let value: Output
    private let queue: DispatchQueue?

    convenience init(_ value: Output) {
        self.init(value, queue: .main)
    }

    private init(_ value: Output, queue: DispatchQueue?) {
        self.value = value
        self.queue = queue
        super.init()
    }

    override func receiveFirstValueSynchronously() -> StorageValuePublisher<Output> {
        StaticStorageValuePublisher(value, queue: nil)
    }

    override func receive(on queue: DispatchQueue) -> StorageValuePublisher<Output> {
        StaticStorageValuePublisher(value, queue: queue)
    }

    override func map<T>(_ transform: @escaping (Output) -> T) -> StorageValuePublisher<T> {
        StaticStorageValuePublisher<T>(transform(value), queue: queue)
    }

    override func removeDuplicates() -> StorageValuePublisher<Output> where Output: Equatable { self }

    override func receive<S>(subscriber: S) where Output == S.Input, S: Subscriber, S.Failure == Error {
        let publisher = Just(value)
            .setFailureType(to: Failure.self)

        if let queue {
            publisher
                .receive(on: queue)
                .receive(subscriber: subscriber)

        } else {
            publisher
                .receive(subscriber: subscriber)
        }
    }
}
