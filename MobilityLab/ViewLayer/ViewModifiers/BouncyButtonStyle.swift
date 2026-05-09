//
//  BouncyButtonStyle.swift
//  MobilityLab
//
//  Created by Josh Franco on 12/4/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
    }
}

extension View {
    func bouncyBtnStyle() -> some View {
        buttonStyle(BouncyButtonStyle())
    }
}

struct BouncyButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button(action: {
            // Do Stuff
        }, label: {
            Text("Button")
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(5)
        })
        .bouncyBtnStyle()
    }
}
