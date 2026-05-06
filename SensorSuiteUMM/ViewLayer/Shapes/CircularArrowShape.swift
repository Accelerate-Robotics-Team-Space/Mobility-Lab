//
//  CircularArrowShape.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct CircularArrowShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let lineWidth: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let pointerLineLength: CGFloat = 15
        let arrowAngle = CGFloat(Angle(degrees: 45).radians)
        
        path.addArc(center: .init(x: rect.midX, y: rect.midY),
                    radius: rect.width * 0.5,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        
        let end = path.currentPoint ?? CGPoint()
        let startEndAngle = CGFloat(endAngle.radians - (3 * Double.pi / 2))
        
        let arrowLine1 = CGPoint(x: end.x + pointerLineLength * cos(CGFloat(Double.pi) - startEndAngle + arrowAngle),
                                 y: end.y - pointerLineLength * sin(CGFloat(Double.pi) - startEndAngle + arrowAngle))
        let arrowLine2 = CGPoint(x: end.x + pointerLineLength * cos(CGFloat(Double.pi) - startEndAngle - arrowAngle),
                                 y: end.y - pointerLineLength * sin(CGFloat(Double.pi) - startEndAngle - arrowAngle))
        
        path.addLine(to: arrowLine1)
        path.move(to: end)
        path.addLine(to: arrowLine2)
        
        return path.strokedPath(.init(lineWidth: lineWidth, lineCap: .round, lineJoin: .bevel))
    }
    
    init(startAngle: Double, endAngle: Double, lineWidth: Double = 5) {
        self.startAngle = Angle(degrees: startAngle)
        self.endAngle = Angle(degrees: endAngle)
        self.lineWidth = CGFloat(lineWidth)
    }
}

struct CircularArrowShape_Previews: PreviewProvider {
    static var previews: some View {
        CircularArrowShape(startAngle: 0, endAngle: 90)
            .frame(width: 100, height: 100)
    }
}
