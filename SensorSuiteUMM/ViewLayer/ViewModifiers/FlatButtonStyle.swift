//
//  FlatButtonStyle.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/19/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct FlatButtonStyle: ButtonStyle {
    let btnStyle: Style
    
    enum Style: Equatable {
        case primary(subtype: Subtype = .default)
        case secondary(subtype: Subtype = .default)
        case clear(subtype: Subtype = .default)
        
        enum Subtype {
            case `default`
            case default2
            case destructive
            case disabled
        }
        
        var backgroundColor: Color {
            switch self {
            case .primary(let subtype):
                switch subtype {
                case .default:
                    return .aqua1
                case .default2:
                    return .green1
                case .destructive:
                    return .vermillion
                case .disabled:
                    return .aqua5
                }
            case .secondary(let subtype):
                switch subtype {
                case .default:
                    return .aqua1.opacity(0.2)
                case .default2:
                    return .green1
                case .destructive:
                    return .charcoal.opacity(0.2)
                case .disabled:
                    return .silver.opacity(0.2)
                }
            case .clear(let subtype):
                switch subtype {
                case .default, .default2, .destructive, .disabled:
                    return .clear
                }
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary(let subtype):
                switch subtype {
                case .default, .default2, .destructive, .disabled:
                    return .white
                }
            case .secondary(let subtype):
                switch subtype {
                case .default:
                    return .aqua1
                case .default2:
                    return .green1
                case .destructive:
                    return .charcoal
                case .disabled:
                    return .silver
                }
            case .clear(let subtype):
                switch subtype {
                case .default:
                    return .aqua1
                case .default2:
                    return .green1
                case .destructive:
                    return .red1
                case .disabled:
                    return .silver
                }
            }
        }
        
        var isDisbaled: Bool {
            let primeDiabled = Style.primary(subtype: .disabled)
            let secDisabled = Style.secondary(subtype: .disabled)
            
            return (self == primeDiabled) || (self == secDisabled)
        }
    }
    
    // MARK: - MakeBody
    func makeBody(configuration: Configuration) -> some View {
        if btnStyle == .clear(subtype: .default) ||
            btnStyle == .clear(subtype: .default2) ||
            btnStyle == .clear(subtype: .destructive) ||
            btnStyle == .clear(subtype: .disabled) {
            configuration.label
                .textStyle(.btn, color: btnStyle.textColor)
                .multilineTextAlignment(.center)
                .padding(.all, 12)
                .background(btnStyle.backgroundColor)
                .frame(minWidth: 44, minHeight: 44)
                .clipShape(RoundedRectangle(cornerRadius: 2000))
                .scaleEffect(configuration.isPressed ? 0.9 : 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 2000)
                        .stroke(btnStyle.textColor, lineWidth: 1)
                )
        } else {
            configuration.label
                .textStyle(.btn, color: btnStyle.textColor)
                .multilineTextAlignment(.center)
                .padding(.all, 12)
                .background(btnStyle.backgroundColor)
                .frame(minWidth: 44, minHeight: 44)
                .clipShape(RoundedRectangle(cornerRadius: 2000))
                .scaleEffect(configuration.isPressed ? 0.9 : 1)
        }
    }
    
    // MARK: - Init
    init(_ style: Style) {
        btnStyle = style
    }
}

extension View {
    func flatBtnStyle(_ style: FlatButtonStyle.Style = .primary()) -> some View {
        buttonStyle(FlatButtonStyle(style))
    }
}

// MARK: - Preview
struct FlatButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Button(action: {
                // Do Stuff
            }, label: {
                Text("Button")
            })
            .flatBtnStyle(.clear(subtype: .destructive))
            
            Button(action: {
                // Do Stuff
            }, label: {
                Text("Button")
            })
            .flatBtnStyle(.clear(subtype: .default2))
        }
    }
}
