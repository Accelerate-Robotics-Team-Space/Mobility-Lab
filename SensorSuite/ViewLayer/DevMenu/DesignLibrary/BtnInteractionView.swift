//
//  BtnInteractionView.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/11/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BtnInteractionView: View {
    @State private var exitBtnToggle = true
    @State private var directionalBtnToggle = true
    @State private var btnToggle = true
    @State private var lgBtnToggle = true
    
    var body: some View {
        VStack(spacing: 52) {            
            ExitBtn(exitBtnToggle ? .primary() : .secondary()) {
                exitBtnToggle.toggle()
            }
            
            DirectionalBtn(directionalBtnToggle ? .left : .right, style: .primary(), labelStr: "Button") {
                directionalBtnToggle.toggle()
            }
            
            Button(action: {
                btnToggle.toggle()
            }, label: {
                Text("Button")
            })
            .buttonStyle(FlatButtonStyle(btnToggle ? .primary() : .secondary()))

            Button(action: {
                lgBtnToggle.toggle()
            }, label: {
                Text("Button")
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(FlatButtonStyle(.primary(subtype: lgBtnToggle ? .default : .destructive)))
            .padding(.horizontal)
        }
        .navigationBarTitle("Button Interactions")
    }
}

struct BtnInteractionView_Previews: PreviewProvider {
    static var previews: some View {
        BtnInteractionView()
    }
}
