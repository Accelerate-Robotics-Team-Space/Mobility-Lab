//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

enum DataFeedResult {
    case newRequest(request: DataFeedRequest)
    case confirmed(confirmation: DataFeedConfirmation)
    case calibrationPoint(confirmation: Bool)
}

enum DataPointResult {
    case dataPointResult(response: DataPoint)
}
