//
//  WearableButtonStyle.swift
//  MobilityLab WatchKit Extension
//
//  Created by Josh Franco on 2/18/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct WearableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
    }
}

struct WearableButtonStyle_Previews: PreviewProvider {
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
        .buttonStyle(WearableButtonStyle())
    }
}
