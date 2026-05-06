//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import Dispatch

class StorageValuePublisher<Output>: Publisher, AsyncSequence {
    typealias Output = Output
    typealias Element = Output
    typealias Failure = Error

    init() { }

    // swiftlint:disable unavailable_function
    func receive<S>(subscriber: S) where S: Subscriber, Error == S.Failure, Output == S.Input {
        preconditionFailure("Please don't use `StorageValuePublisher` directly. You should use the `GRDBStorageValuePublisher` subclass.")
    }

    func makeAsyncIterator() -> StorageValueIterator<Output> {
        preconditionFailure("Please don't use `StorageValuePublisher` directly. You should use the `GRDBStorageValuePublisher` subclass.")
    }

    @MainActor
    func receiveFirstValueSynchronously() -> StorageValuePublisher<Output> {
        preconditionFailure("Please don't use `StorageValuePublisher` directly. You should use the `GRDBStorageValuePublisher` subclass.")
    }

    func receive(on queue: DispatchQueue) -> StorageValuePublisher<Output> {
        preconditionFailure("Please don't use `StorageValuePublisher` directly. You should use the `GRDBStorageValuePublisher` subclass.")
    }

    func map<T>(_ transform: @escaping (Output) -> T) -> StorageValuePublisher<T> {
        preconditionFailure("Please don't use `StorageValuePublisher` directly. You should use the `GRDBStorageValuePublisher` subclass.")
    }

    func removeDuplicates() -> StorageValuePublisher<Output> where Output: Equatable {
        preconditionFailure("Please don't use `StorageValuePublisher` directly. You should use the `GRDBStorageValuePublisher` subclass.")
    }
    // swiftlint:enable unavailable_function

    @MainActor
    static func just<T>(_ value: T) -> StorageValuePublisher<T> {
        StaticStorageValuePublisher(value).receiveFirstValueSynchronously()
    }
}

// MARK: - Storage Value Iterator
class StorageValueIterator<Element>: AsyncIteratorProtocol {
    typealias Element = Element

    init() { }

    // swiftlint:disable:next unavailable_function
    func next() async throws -> Element? {
        preconditionFailure("Please don't use `StorageValueIterator` directly. You should use the `GRDBStorageValueIterator` subclass.")
    }
}
