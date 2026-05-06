//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import Dispatch

final class FailingStorageValuePublisher<Output>: StorageValuePublisher<Output> {
    let error: Error
    private let queue: DispatchQueue?

    convenience init(error: Error) {
        self.init(error: error, queue: .main)
    }

    private init(error: Error, queue: DispatchQueue?) {
        self.error = error
        self.queue = queue
        super.init()
    }

    override func receiveFirstValueSynchronously() -> StorageValuePublisher<Output> {
        FailingStorageValuePublisher(error: error, queue: nil)
    }

    override func receive(on queue: DispatchQueue) -> StorageValuePublisher<Output> {
        FailingStorageValuePublisher(error: error, queue: queue)
    }

    override func map<T>(_ transform: @escaping (Output) -> T) -> StorageValuePublisher<T> {
        FailingStorageValuePublisher<T>(error: error, queue: queue)
    }

    override func removeDuplicates() -> StorageValuePublisher<Output> where Output: Equatable { self }

    override func receive<S>(subscriber: S) where Output == S.Input, S: Subscriber, S.Failure == Error {
        if let queue {
            Fail(error: error)
                .receive(on: queue)
                .receive(subscriber: subscriber)

        } else {
            Fail(error: error)
                .receive(subscriber: subscriber)
        }
    }

    override func makeAsyncIterator() -> StorageValueIterator<Output> {
        FailingStorageValueIterator(error: error)
    }
}

private final class FailingStorageValueIterator<Output>: StorageValueIterator<Output> {
    let error: Error

    init(error: Error) {
        self.error = error
        super.init()
    }

    override func next() async throws -> Output? { throw error }
}
