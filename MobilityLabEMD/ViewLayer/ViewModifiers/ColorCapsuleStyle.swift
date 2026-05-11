//
//  ColorCapsuleStyle.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 5/31/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ColorCapsuleStyle: ViewModifier {
    let color: Color
    let textColor: Color
    let filled: Bool
    
    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(.center)
            .padding(.top, 4)
            .padding(.bottom, 3)
            .padding([.leading, .trailing], 8)
            .conditionalModifier(filled) {
                $0.background(color)
            }
            .conditionalModifier(filled) {
                $0.foregroundColor(textColor)
            }
            .conditionalModifier(!filled) {
                $0.foregroundColor(color)
            }
            .clipShape(RoundedRectangle(cornerRadius: 2000))
            .overlay(
                RoundedRectangle(cornerRadius: 2000)
                    .stroke(color, lineWidth: 1)
            )
    }
    
    // MARK: - Init
    init(color: Color, textColor: Color, filled: Bool = true) {
        self.color = color
        self.textColor = textColor
        self.filled = filled
    }
}

extension View {
    func colorCapsuleCard(color: Color, textColor: Color = .white, filled: Bool = true) -> some View {
        if filled {
            return self.modifier(ColorCapsuleStyle(color: color, textColor: textColor, filled: filled))
        } else {
            return self.modifier(ColorCapsuleStyle(color: color, textColor: color, filled: filled))
        }
    }
}

struct ColorCapsuleStyle_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Text("Hello, World!")
                        .colorCapsuleCard(color: .indigo1)
                    Text("Hello, World!")
                        .colorCapsuleCard(color: .indigo1, filled: false)
                }
                HStack {
                    Text("Hello, World!")
                        .colorCapsuleCard(color: .yellow1)
                    Text("Hello, World!")
                        .colorCapsuleCard(color: .yellow1, filled: false)
                }
                HStack {
                    Text("Hello, World!")
                        .colorCapsuleCard(color: .red1)
                    Text("Hello, World!")
                        .colorCapsuleCard(color: .red1, filled: false)
                }
            }
        }
        .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
