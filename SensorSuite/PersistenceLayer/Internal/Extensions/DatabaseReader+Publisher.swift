//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import GRDB

extension DatabaseReader {
    func publisher<Value: Equatable>(
        isImmediate: Bool,
        observeChanges: Bool = true,
        tracking value: @escaping (Database) throws -> Value
    ) -> AnyPublisher<Value, Error> {
        guard observeChanges else {
            return readPublisher(value: value)
                .removeDuplicates()
                .eraseToAnyPublisher()
        }

        let scheduler: ValueObservationScheduler = isImmediate ? .immediate : .async(onQueue: .main)

        return ValueObservation.tracking(value)
            .publisher(in: self, scheduling: scheduler)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
