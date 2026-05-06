//
//  SunrayBackground.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 11/4/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct SunrayBackground: View {
    var body: some View {
        GeometryReader { _ in
            VStack(alignment: .center) {
                    ZStack {
                        Rectangle()
                            .fill(
                                RadialGradient(gradient: Gradient(colors: [
                                    Color(hex: 0xF5BC5E, opacity: 0.7),
                                    Color(hex: 0xF5BC5E, opacity: 0),
                                ]),
                                               center: .top,
                                               startRadius: 0,
                                               endRadius: 400)
                            )
                            .frame(width: 834, height: 828)
                            .cornerRadius(0)
                            .ignoresSafeArea()
                        Image(R.image.monitoringRay.name)
                            .resizable()
                            .frame(width: 834, height: 828)
                            .scaledToFit()
                            .ignoresSafeArea()
                    }
            }
        }
    }
}

struct SunrayBackground_Previews: PreviewProvider {
    static var previews: some View {
        SunrayBackground()
    }
}
