//
//  SingleDotShape.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 10/19/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct SingleDotShape: View {
    @State var delay: Double = 0
    @State var scale: CGFloat = 1
    var body: some View {
        Circle()
            .foregroundColor(.white)
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .opacity(Double(1 - scale))
            .onAppear {
                withAnimation(.easeIn(duration: 1).repeatForever(autoreverses: false).delay(delay)) {
                    self.scale = 0.2
                }
            }
    }
}

struct SingleDotShape_Previews: PreviewProvider {
    static var previews: some View {
        SingleDotShape()
    }
}
