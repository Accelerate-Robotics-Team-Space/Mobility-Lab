//
//  SquareIndicatorShape.swift
//  MobilityLab
//
//  Created by Josh Franco on 9/15/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct SquareIndicatorShape: Shape {
    var indicatorLength: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 4 Corners
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLines([
            CGPoint(x: rect.minX, y: rect.maxY - indicatorLength),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.minX + indicatorLength, y: rect.maxY),
        ])

        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLines([
            CGPoint(x: rect.maxX, y: rect.minY + indicatorLength),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX - indicatorLength, y: rect.minY),
        ])

        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLines([
            CGPoint(x: rect.maxX, y: rect.maxY - indicatorLength),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.maxX - indicatorLength, y: rect.maxY),
        ])

        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLines([
            CGPoint(x: rect.minX, y: rect.minY + indicatorLength),
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.minX + indicatorLength, y: rect.minY),
        ])

        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLines([
            CGPoint(x: rect.midX - indicatorLength, y: rect.minY),
            CGPoint(x: rect.midX + indicatorLength, y: rect.minY),
        ])

        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLines([
            CGPoint(x: rect.midX - indicatorLength, y: rect.maxY),
            CGPoint(x: rect.midX + indicatorLength, y: rect.maxY),
        ])

        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLines([
            CGPoint(x: rect.minX, y: rect.midY - indicatorLength),
            CGPoint(x: rect.minX, y: rect.midY + indicatorLength),
        ])

        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLines([
            CGPoint(x: rect.maxX, y: rect.midY - indicatorLength),
            CGPoint(x: rect.maxX, y: rect.midY + indicatorLength),
        ])
        return path
    }
}

struct SquareIndicatorShape_Previews: PreviewProvider {
    static var previews: some View {
        SquareIndicatorShape(indicatorLength: 48)
            .stroke(lineWidth: 5)
            .foregroundColor(.red)
            .frame(width: 300, height: 300)
    }
}
