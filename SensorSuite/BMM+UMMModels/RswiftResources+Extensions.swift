// swiftlint:disable:this file_name
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import RswiftResources
import SwiftUI

extension FontResource {
    func font(size: CGFloat) -> Font {
        Font.custom(name, size: size)
    }
}

extension RswiftResources.ColorResource {
    var color: Color {
        Color(name)
    }
}

extension RswiftResources.StringResource {
    var localizedStringKey: LocalizedStringKey {
        LocalizedStringKey(callAsFunction())
    }

    var text: Text {
        Text(localizedStringKey)
    }
}

extension RswiftResources.ImageResource {
    var image: Image {
        Image(name)
    }
}
