//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
import SwiftUI

struct HeadOfBedSideImage {
    static func from(position: PositionalFlagCategory, rised: Bool) -> Image {
        if position == .left {
            return Image(rised ? R.image.leftRised.name : R.image.leftPlain.name)
        } else if position == .right {
            return Image(rised ? R.image.rightRised.name : R.image.rightPlain.name)
        } else {
            return Image(R.image.zeroDegree.name)
        }
    }
}
