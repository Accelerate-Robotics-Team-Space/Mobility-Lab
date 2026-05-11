//
//  ExitBtnView.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/6/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ExitBtn: View {
    private var btnStyle: FlatButtonStyle.Style
    private var btnAction: () -> Void
    
    // MARK: - Body
    var body: some View {
        Button(action: btnAction, label: {
            Image(R.image.componentClose.name)
                .renderingMode(.template)
        })
        .buttonStyle(FlatButtonStyle(btnStyle))
        .disabled(btnStyle.isDisbaled)
    }
    
    // MARK: - Init
    init(_ someStyle: FlatButtonStyle.Style = .primary(), action: @escaping () -> Void) {
        btnStyle = someStyle
        btnAction = action
    }
}

// MARK: - Preview
struct ExitBtnView_Previews: PreviewProvider {
    static var previews: some View {
        ExitBtn(.primary(subtype: .default)) {
            // Do stuff
        }
    }
}
