//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import Dispatch

final class CombineStorageValuePublisher<Upstream>: StorageValuePublisher<Upstream.Output> where Upstream: Publisher, Upstream.Failure == Error {
    private let upstream: Upstream
    private let queue: DispatchQueue?

    // MARK: - Initialisation

    convenience init(upstream: Upstream) {
        self.init(upstream, queue: .main)
    }

    init(_ upstream: Upstream, queue: DispatchQueue?) {
        self.upstream = upstream
        self.queue = queue
        super.init()
    }

    override func receiveFirstValueSynchronously() -> StorageValuePublisher<Output> {
        CombineStorageValuePublisher(upstream, queue: nil)
    }

    override func receive(on queue: DispatchQueue) -> StorageValuePublisher<Output> {
        CombineStorageValuePublisher(upstream, queue: queue)
    }

    override func map<T>(_ transform: @escaping (Output) -> T) -> StorageValuePublisher<T> {
        CombineStorageValuePublisher<Publishers.Map<Upstream, T>>(
            upstream.map(transform),
            queue: queue
        )
    }

    override func removeDuplicates() -> StorageValuePublisher<Output> where Output: Equatable {
        CombineStorageValuePublisher<Publishers.RemoveDuplicates<Upstream>>(
            upstream.removeDuplicates(),
            queue: queue
        )
    }

    override func receive<S>(subscriber: S) where Upstream.Output == S.Input, S: Subscriber, S.Failure == Error {
        if let queue {
            upstream
                .receive(on: queue)
                .receive(subscriber: subscriber)
        } else {
            upstream
                .receive(subscriber: subscriber)
        }
    }

    override func makeAsyncIterator() -> StorageValueIterator<Upstream.Output> {
        CombineStorageValueIterator(upstream: upstream)
    }
}

private final class CombineStorageValueIterator<Upstream>: StorageValueIterator<Upstream.Output> where Upstream: Publisher, Upstream.Failure == Error {
    var iterator: AsyncThrowingPublisher<Upstream>.Iterator

    init(upstream: Upstream) {
        self.iterator = upstream.values.makeAsyncIterator()
    }

    override func next() async throws -> Upstream.Output? {
        try await iterator.next()
    }
}

// MARK: - Convenience Initialisers
extension CombineStorageValuePublisher {
    convenience init<Other>(upstream: Other) where Other: Publisher, Other.Failure == Never, Upstream == Publishers.SetFailureType<Other, Error> {
        self.init(upstream: upstream.setFailureType(to: Error.self))
    }
}
