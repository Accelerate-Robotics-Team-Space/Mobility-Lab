//
//  CapsuleStyle.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/25/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct CapsuleStyle: ViewModifier {
    let style: Style
    let filled: Bool
    
    enum Style {
        case green
        case warning
        case destructive
        case action
        case standby

        var color: Color {
            switch self {
            case .green:
                return .green1
            case .warning:
                return .yellow1
            case .destructive:
                return .red1
            case .action:
                return .indigo1
            case .standby:
                return .charcoal3
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(.center)
            .padding(.top, 4)
            .padding(.bottom, 3)
            .padding([.leading, .trailing], 8)
            .conditionalModifier(filled) {
                $0.background(style.color)
            }
            .conditionalModifier(filled) {
                $0.foregroundColor(.white)
            }
            .conditionalModifier(!filled) {
                $0.foregroundColor(style.color)
            }
            .clipShape(RoundedRectangle(cornerRadius: 2000))
            .overlay(
                RoundedRectangle(cornerRadius: 2000)
                    .stroke(style.color, lineWidth: 1)
            )
    }
    
    // MARK: - Init
    init(_ style: Style, filled: Bool = true) {
        self.style = style
        self.filled = filled
    }
}

extension View {
    func capsuleCard(_ style: CapsuleStyle.Style = .green, filled: Bool = true) -> some View {
        self.modifier(CapsuleStyle(style, filled: filled))
    }
    
    func capsuleCard(alertLevel: AlertLevel) -> some View {
        switch alertLevel {
        case .green:
            return self.modifier(CapsuleStyle(.green))
        case .warning:
            return self.modifier(CapsuleStyle(.warning))
        case .critical:
            return self.modifier(CapsuleStyle(.destructive))
        case .action:
            return self.modifier(CapsuleStyle(.action))
        case .none:
            return self.modifier(CapsuleStyle(.standby))
        }
    }
}

struct CapsuleStyle_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Text("Hello, World!")
                        .capsuleCard()
                    Text("Hello, World!")
                        .capsuleCard(filled: false)
                }
                HStack {
                    Text("Hello, World!")
                        .capsuleCard(.warning)
                    Text("Hello, World!")
                        .capsuleCard(.warning, filled: false)
                }
                HStack {
                    Text("Hello, World!")
                        .capsuleCard(.destructive)
                    Text("Hello, World!")
                        .capsuleCard(.destructive, filled: false)
                }
                HStack {
                    Text("Hello, World!")
                        .capsuleCard(.action)
                    Text("Hello, World!")
                        .capsuleCard(.action, filled: false)
                }
                HStack {
                    Text("Hello, World!")
                        .capsuleCard(.standby)
                    Text("Hello, World!")
                        .capsuleCard(.standby, filled: false)
                }
            }
        }
        .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
