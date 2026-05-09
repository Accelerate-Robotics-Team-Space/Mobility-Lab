//
//  SingleDotShape.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/28/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct SingleDotShape: View {
    @State var delay: Double = 0
    @State private var scale = 1.0
    @State private var opacity: Double = 1.0
    var body: some View {
        Circle()
            .foregroundColor(.aqua1)
            .frame(width: 6, height: 6)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                self.scale = 1.0
                self.opacity = 0.0
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true).delay(delay)) {
                    self.scale = 0.2
                    self.opacity = 0.8
                }
            }
            .ignoresSafeArea()
    }
}

struct SingleDotShape_Previews: PreviewProvider {
    static var previews: some View {
        SingleDotShape()
    }
}
