//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            switch edge {
            case .top:
                path.move(to: .init(x: rect.minX, y: rect.minY) )
                path.addLine(to: .init(x: rect.maxX, y: rect.minY))
            case .bottom:
                path.move(to: .init(x: rect.minX, y: rect.maxY) )
                path.addLine(to: .init(x: rect.maxX, y: rect.maxY))
            case .leading:
                path.move(to: .init(x: rect.minX, y: rect.minY) )
                path.addLine(to: .init(x: rect.minX, y: rect.maxY))
            case .trailing:
                path.move(to: .init(x: rect.maxX, y: rect.minY) )
                path.addLine(to: .init(x: rect.maxX, y: rect.maxY))
            }
        }
        return path
    }
}
