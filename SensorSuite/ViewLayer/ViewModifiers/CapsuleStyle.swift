//
//  CapsuleStyle.swift
//  SensorSuite
//
//  Created by Josh Franco on 7/22/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct CapsuleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .circular))
    }
}

extension View {
    func capsuleCard() -> some View {
        self.modifier(CapsuleStyle())
    }
}

struct CapsuleStyle_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            Text("Hello, World!")
                .capsuleCard()
        }
        .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
