// swiftlint:disable:this file_name
//  LineShape.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

struct LineShape_Previews: PreviewProvider {
    static var previews: some View {
        Line()
            .stroke(lineWidth: 5)
            .foregroundColor(.red)
    }
}
