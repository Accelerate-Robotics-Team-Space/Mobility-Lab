//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import Dispatch
import GRDB

/// Wrapper for GRDB's Value Observation: https://swiftpackageindex.com/groue/grdb.swift/v6.29.3/documentation/grdb/valueobservation
class GRDBStorageValuePublisher<Output, Reducer>: StorageValuePublisher<Output> where Reducer: ValueReducer, Reducer.Value == Output {
    enum TrackingMode {
        case variableRegions
        case constantRegions
        case specificRegions([any DatabaseRegionConvertible])
        static func specificRegion(_ region: any DatabaseRegionConvertible) -> Self { .specificRegions([ region ]) }
    }

    let database: DatabaseReader
    let observer: ValueObservation<Reducer>
    private(set) var scheduler: ValueObservationScheduler

    private init(database: DatabaseReader, observer: ValueObservation<Reducer>, scheduler: ValueObservationScheduler) {
        self.database = database
        self.observer = observer
        self.scheduler = scheduler
    }

    @MainActor
    override func receiveFirstValueSynchronously() -> Self {
        scheduler = .immediate
        return self
    }

    override func receive(on queue: DispatchQueue) -> Self {
        scheduler = .async(onQueue: queue)
        return self
    }

    private func makeDatabasePublisher() -> DatabasePublishers.Value<Output> {
        observer.publisher(in: database, scheduling: scheduler)
    }

    override func receive<S>(subscriber: S) where Output == S.Input, S: Subscriber, S.Failure == Error {
        makeDatabasePublisher().receive(subscriber: subscriber)
    }

    override func makeAsyncIterator() -> StorageValueIterator<Output> {
        let sequence = makeDatabasePublisher()
            .infiniteBuffer()
            .values
        return GRDBStorageValueIterator(sequence)
    }

    override func map<T>(_ transform: @escaping (Output) -> T) -> StorageValuePublisher<T> {
        GRDBStorageValuePublisher<T, ValueReducers.Map<Reducer, T>>(
            database: database,
            observer: observer.map(transform),
            scheduler: scheduler
        )
    }

    override func removeDuplicates() -> StorageValuePublisher<Output> where Output: Equatable {
        GRDBStorageValuePublisher<Output, ValueReducers.RemoveDuplicates<Reducer>>(
            database: database,
            observer: observer.removeDuplicates(),
            scheduler: scheduler
        )
    }

}

extension GRDBStorageValuePublisher where Reducer == ValueReducers.Fetch<Output> {
    typealias Query = (Database) throws -> Output

    convenience init(_ database: DatabaseReader, mode: TrackingMode = .variableRegions, query: @escaping Query) {
        self.init(
            database: database,
            observer: Self.makeObserver(mode: mode, query: query),
            scheduler: .async(onQueue: .main)
        )
    }

    private static func makeObserver(mode: TrackingMode, query: @escaping Query) -> ValueObservation<Reducer> {
        switch mode {
        case .constantRegions:
            return ValueObservation.trackingConstantRegion(query)
        case .variableRegions:
            return ValueObservation.tracking(query)
        case .specificRegions(let regions):
            return ValueObservation.tracking(regions: regions, fetch: query)
        }
    }
}

// MARK: - Debugging

extension GRDBStorageValuePublisher {
    func handleEvents(
        willStart: (() -> Void)? = nil,
        willFetch: (() -> Void)? = nil,
        willTrackRegion: ((DatabaseRegion) -> Void)? = nil,
        databaseDidChange: (() -> Void)? = nil,
        didReceiveValue: ((Reducer.Value) -> Void)? = nil,
        didFail: ((Error) -> Void)? = nil,
        didCancel: (() -> Void)? = nil
    ) -> GRDBStorageValuePublisher<Output, ValueReducers.Trace<Reducer>> {
        GRDBStorageValuePublisher<Output, ValueReducers.Trace<Reducer>>(
            database: database,
            observer: observer
                .handleEvents(
                    willStart: willStart,
                    willFetch: willFetch,
                    willTrackRegion: willTrackRegion,
                    databaseDidChange: databaseDidChange,
                    didReceiveValue: didReceiveValue,
                    didFail: didFail,
                    didCancel: didCancel
                ),
            scheduler: scheduler
        )
    }
}
