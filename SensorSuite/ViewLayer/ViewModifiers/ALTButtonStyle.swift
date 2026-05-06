//
//  ALTButtonStyle.swift
//  SensorSuite
//
//  Created by Vadym Riznychok on 5/10/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ALTButtonStyle: ButtonStyle {
    private var textStyle: TextStyle.Style = .bold
    private var textColor: Color = .white
    private var backgroundColor: Color = .indigo1
    private var borderColor: Color = .indigo1

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(textStyle, color: textColor)
            .multilineTextAlignment(.center)
            .padding(.all, 12)
            .background(backgroundColor)
            .frame(minWidth: 43, minHeight: 43)
            .clipShape(RoundedRectangle(cornerRadius: 2000))
            .overlay(
                RoundedRectangle(cornerRadius: 2000)
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.interactiveSpring(), value: configuration.isPressed)
    }

    // MARK: - Builders
    func textStyle(_ style: TextStyle.Style) -> ALTButtonStyle {
        var btn = self
        btn.textStyle = style
        return btn
    }

    func textColor(_ color: Color) -> ALTButtonStyle {
        var btn = self
        btn.textColor = color
        return btn
    }

    func backgroundAndBorderColor(_ color: Color) -> ALTButtonStyle {
        var btn = self
        btn.backgroundColor = color
        btn.borderColor = color
        return btn
    }

    func backgroundColor(_ color: Color) -> ALTButtonStyle {
        var btn = self
        btn.backgroundColor = color
        return btn
    }

    func borderColor(_ color: Color) -> ALTButtonStyle {
        var btn = self
        btn.borderColor = color
        return btn
    }

    // MARK: - Presets
    static func altBtnPlainWhite() -> ALTButtonStyle {
        ALTButtonStyle().textColor(.indigo1).backgroundAndBorderColor(.white)
    }

    static func altBtnIndigoDisabled() -> ALTButtonStyle {
        ALTButtonStyle().textColor(.white).backgroundAndBorderColor(.indigo5)
    }

    static func altBtnDismiss() -> ALTButtonStyle {
        ALTButtonStyle().textColor(.indigo2).backgroundAndBorderColor(.indigo5)
    }

    static func altBtnSecondaryBordered() -> ALTButtonStyle {
        ALTButtonStyle().textColor(.indigo1).backgroundColor(.white).borderColor(.indigo1)
    }

    static func altBtnWhiteRedBorder() -> ALTButtonStyle {
        ALTButtonStyle().textColor(.red1).backgroundColor(.white).borderColor(.red1)
    }
}

extension View {
    func altButtonCustom(textStyle: TextStyle.Style = .bold,
                         textColor: Color = .indigo1,
                         backgroundColor: Color = .indigo1,
                         borderColor: Color = .indigo1) -> some View {
        buttonStyle(ALTButtonStyle()
            .textStyle(textStyle)
            .textColor(textColor)
            .backgroundColor(backgroundColor)
            .borderColor(borderColor))
    }

    func altBtnIndigo() -> some View {
        buttonStyle(ALTButtonStyle())
    }

    func altBtnPlainWhite() -> some View {
        buttonStyle(ALTButtonStyle.altBtnPlainWhite())
    }

    func altBtnIndigoDisabled() -> some View {
        buttonStyle(ALTButtonStyle.altBtnIndigoDisabled())
    }

    func altBtnDismiss() -> some View {
        buttonStyle(ALTButtonStyle.altBtnDismiss())
    }

    func altBtnSecondaryBordered() -> some View {
        buttonStyle(ALTButtonStyle.altBtnSecondaryBordered())
    }

    func altBtnWhiteRedBorder() -> some View {
        buttonStyle(ALTButtonStyle.altBtnWhiteRedBorder())
    }
}

struct IndigoButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 16, content: {
                Button(action: {
                    // Do Stuff
                }, label: {
                    Text("Action")
                        .frame(width: 200)
                })
                .altBtnIndigo()
                Button(action: {
                    // Do Stuff
                }, label: {
                    Text("Plain")
                        .frame(width: 200)
                })
                .altBtnPlainWhite()
                Button(action: {
                    // Do Stuff
                }, label: {
                    Text("Action disabled")
                        .frame(width: 200)
                })
                .altBtnIndigoDisabled()
                Button(action: {
                    // Do Stuff
                }, label: {
                    Text("Dismiss")
                        .frame(width: 200)
                })
                .altBtnDismiss()
                Button(action: {
                    // Do Stuff
                }, label: {
                    Text("Secondary bordered")
                        .frame(width: 200)
                })
                .altBtnSecondaryBordered()
                Button(action: {
                    // Do Stuff
                }, label: {
                    Text("Cancel")
                        .frame(width: 200)
                })
                .altBtnWhiteRedBorder()
            })
        }
    }
}
