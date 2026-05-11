//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation

extension Publisher {

    // adapted from https://stackoverflow.com/a/67133582

    /// Includes the current element as well as the previous element from the upstream publisher in a tuple where the previous element is optional.
    /// The first time the upstream publisher emits an element, the previous element will be `nil`.
    ///
    ///     let range = (1...5)
    ///     cancellable = range.publisher
    ///         .withPrevious()
    ///         .sink { print ("(\($0.previous), \($0.current))", terminator: " ") }
    ///      // Prints: "(nil, 1) (Optional(1), 2) (Optional(2), 3) (Optional(3), 4) (Optional(4), 5) ".
    ///
    /// - Returns: A publisher of a tuple of the previous and current elements from the upstream publisher.
    func withPrevious() -> Publishers.CompactMap<Publishers.Scan<Self, Optional<(previous: Self.Output?, current: Self.Output)>>, (previous: Self.Output?, current: Self.Output)> {
        scan(Optional<(Output?, Output)>.none) { ($0?.1, $1) }
            .compactMap { $0 }
            .map { (previous: $0.0, current: $0.1) }
    }

    /// Includes the current element as well as the previous element from the upstream publisher in a tuple where the previous element is not optional.
    /// The first time the upstream publisher emits an element, the previous element will be the `initialPreviousValue`.
    ///
    ///     let range = (1...5)
    ///     cancellable = range.publisher
    ///         .withPrevious(0)
    ///         .sink { print ("(\($0.previous), \($0.current))", terminator: " ") }
    ///      // Prints: "(0, 1) (1, 2) (2, 3) (3, 4) (4, 5) ".
    ///
    /// - Parameter initialPreviousValue: The initial value to use as the "previous" value when the upstream publisher emits for the first time.
    /// - Returns: A publisher of a tuple of the previous and current elements from the upstream publisher.
    func withPrevious(_ initialPreviousValue: Output) -> Publishers.Scan<Self, (previous: Self.Output, current: Self.Output)> {
        scan((initialPreviousValue, initialPreviousValue)) { (previous: $0.1, current: $1) }
    }

    func withPrevious<T>() -> Publishers.CompactMap<Publishers.Scan<Self, Optional<(T?, T?)>>, (previous: T?, current: T?)> where Output == T? {
        scan(Optional<(Output, Output)>.none) { ($0?.1, $1) }
            .compactMap { $0 }
            .map { (previous: $0.0, current: $0.1) }
    }

    func infiniteBuffer() -> Publishers.Buffer<Self> {
        buffer(size: .max, prefetch: .byRequest, whenFull: .customError {
            fatalError("Can't fill an infinite buffer")
        })
    }

    func asyncMap<T>(_ transform: @escaping (Output) async -> T) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    let output = await transform(value)
                    promise(.success(output))
                }
            }
        }
    }

    func asyncMap<T>(_ transform: @escaping (Output) async throws -> T) -> Publishers.FlatMap<Future<T, Error>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    do {
                        let output = try await transform(value)
                        promise(.success(output))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }

    func asyncMap<T>(_ transform: @escaping (Output) async throws -> T) -> Publishers.FlatMap<Future<T, Error>, Publishers.SetFailureType<Self, Error>> {
        flatMap { value in
            Future { promise in
                Task {
                    do {
                        let output = try await transform(value)
                        promise(.success(output))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}
