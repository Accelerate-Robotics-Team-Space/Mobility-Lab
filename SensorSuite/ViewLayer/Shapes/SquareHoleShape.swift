//
//  SquareHoleShape.swift
//  SensorSuite
//
//  Created by Josh Franco on 9/15/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct SquareHoleShape: Shape {
    var holeSize: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var shape = Rectangle().path(in: rect)
        var path = Path()
        
        let xPoint = rect.midX - (holeSize / 2)
        let yPoint = rect.midY - (holeSize / 2)
        
        path.move(to: CGPoint(x: xPoint, y: yPoint))
        path.addLines([
            CGPoint(x: xPoint, y: yPoint + holeSize),
            CGPoint(x: xPoint + holeSize, y: yPoint + holeSize),
            CGPoint(x: xPoint + holeSize, y: yPoint),
            CGPoint(x: xPoint, y: yPoint),
        ])

        shape.addPath(path)
        return shape
    }
}

struct SquareHoleShape_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Image(systemName: "trash")
                .resizable()
            
            Color.red
                .opacity(0.5)
                .mask(SquareHoleShape(holeSize: 250))
        }
    }
}
