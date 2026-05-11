//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import GRDB

final class GRDBStorageValueIterator<Element>: StorageValueIterator<Element> {
    typealias Sequence = AsyncThrowingPublisher<Publishers.Buffer<DatabasePublishers.Value<Element>>>

    let sequence: Sequence
    var wrapped: Sequence.Iterator

    init(_ sequence: Sequence) {
        self.sequence = sequence
        self.wrapped = sequence.makeAsyncIterator()
        super.init()
    }

    override func next() async throws -> Element? {
        try await wrapped.next()
    }
}
