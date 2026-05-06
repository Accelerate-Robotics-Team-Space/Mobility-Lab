//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import Dispatch

final class EmptyStorageValuePublisher<Output>: StorageValuePublisher<Output> {
    private let queue: DispatchQueue?

    override init() {
        self.queue = .main
        super.init()
    }

    private init(queue: DispatchQueue?) {
        self.queue = queue
        super.init()
    }

    override func receiveFirstValueSynchronously() -> StorageValuePublisher<Output> {
        EmptyStorageValuePublisher(queue: nil)
    }

    override func receive(on queue: DispatchQueue) -> StorageValuePublisher<Output> {
        EmptyStorageValuePublisher(queue: queue)
    }

    override func map<T>(_ transform: @escaping (Output) -> T) -> StorageValuePublisher<T> {
        EmptyStorageValuePublisher<T>(queue: queue)
    }

    override func removeDuplicates() -> StorageValuePublisher<Output> where Output: Equatable {
        EmptyStorageValuePublisher(queue: queue)
    }

    override func receive<S>(subscriber: S) where Output == S.Input, S: Subscriber, S.Failure == Error {
        if let queue {
            Empty()
                .receive(on: queue)
                .receive(subscriber: subscriber)

        } else {
            Empty()
                .receive(subscriber: subscriber)
        }
    }

    override func makeAsyncIterator() -> StorageValueIterator<Output> {
        EmptyStorageValueIterator()
    }
}

private final class EmptyStorageValueIterator<Output>: StorageValueIterator<Output> {
    override func next() async throws -> Output? { nil }
}
