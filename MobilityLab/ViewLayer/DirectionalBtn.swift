//
//  DirectionalBtnView.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/6/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DirectionalBtn: View {
    private var btnText: String
    private var btnAction: () -> Void
    private var btnDirection: Direction
    private var btnStyle: FlatButtonStyle.Style
    
    enum Direction {
        case left
        case right
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: btnAction, label: {
            HStack(spacing: 4) {
                if btnDirection == .left {
                    Image(R.image.chevronLeft.name)
                        .renderingMode(.template)
                        .foregroundColor(btnStyle.textColor)
                }
                
                Text(btnText)
                
                if btnDirection == .right {
                    Image(R.image.chevronRight.name)
                        .renderingMode(.template)
                        .foregroundColor(btnStyle.textColor)
                }
            }
        })
        .buttonStyle(FlatButtonStyle(btnStyle))
    }
    
    // MARK: - Init
    init(_ direction: Direction, style someStyle: FlatButtonStyle.Style,
         labelStr: String, action: @escaping () -> Void) {
        btnText = labelStr
        btnAction = action
        btnDirection = direction
        btnStyle = someStyle
    }
}

// MARK: - Preview
struct DirectionalBtnView_Previews: PreviewProvider {
    static var previews: some View {
        DirectionalBtn(.right, style: .primary(), labelStr: "Some Button") {
            // Do stuff
        }
    }
}
