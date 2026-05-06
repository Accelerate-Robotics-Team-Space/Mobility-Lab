//
//  TextStyle.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/5/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct TextStyle: ViewModifier {
    var fontStyle: Style
    
    enum Style {
        case header1
        case header2
        case header3
        case header4
        case header5
        case header6
        case body
        case body1
        case body2
        case bold
        case subtitle
        case caption
        case overline
        
        var fontName: String {
            switch self {
            case .header1, .header2, .header4, .header5, .header6:
                return "Avenir-Black"
            case .body1, .bold, .header3:
                return "Avenir-Heavy"
            case .body2:
                return "Avenir-Book"
            case .subtitle, .caption, .overline, .body:
                return "Avenir-Roman"
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .header1:
                return 40
            case .header2:
                return 32
            case .header3:
                return 24
            case .header4:
                return 22
            case .header5:
                return 20
            case .header6:
                return 18
            case .body, .body1, .body2, .bold:
                return 16
            case .subtitle:
                return 14
            case .caption:
                return 12
            case .overline:
                return 10
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .font(Font.custom(fontStyle.fontName, size: fontStyle.fontSize))
    }
}

extension View {
    func textStyle(_ style: TextStyle.Style, color: Color = .charcoal) -> some View {
        self.modifier(TextStyle(fontStyle: style)).foregroundColor(color)
    }
}

struct TextStyle_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, World!")
            .previewDevice("iPhone 12")
            .textStyle(.header4, color: .charcoal)
    }
}
