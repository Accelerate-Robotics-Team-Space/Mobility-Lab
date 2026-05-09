// swiftlint:disable:this file_name
//  ToggleStyle.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/24/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation
import SwiftUI

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Rectangle()
                .foregroundColor(.charcoal5)
                .frame(width: 76, height: 38, alignment: .center)
                .overlay(
                    ZStack {
                        HStack(spacing: 18) {
                            Image(R.image.gridMenu.name)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(Color(hex: 0xC4C4C4))
                            Image(R.image.listMenu.name)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 20, height: 14)
                                .foregroundColor(Color(hex: 0xC4C4C4))
                        }
                        Circle()
                            .foregroundColor(.white)
                            .padding(.all, 1)
                            .overlay(
                                GeometryReader { _ in // TODO: Why is this Geometry Reader here?
                                    if !configuration.isOn {
                                        Image(R.image.gridMenu.name)
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(.charcoal1)
                                            .offset(x: 9, y: 9)
                                    } else {
                                        Image(R.image.listMenu.name)
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 20, height: 14)
                                            .foregroundColor(.charcoal1)
                                            .offset(x: 9, y: 12)
                                    }
                                }
                            )
                            .offset(x: configuration.isOn ? 19 : -19, y: 0)
                            .animation(Animation.linear(duration: 0.1), value: configuration.isOn)
                            .shadow(color: .white.opacity(0.1), radius: 12, x: 0, y: 1)
                            .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                )
                .cornerRadius(2000)
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}

// MARK: - Preview
struct ToggleStyle_Previews: PreviewProvider {
    @State static var active = true
    
    static var previews: some View {
        Toggle(isOn: $active, label: {
            Text("Active")
        })
        .toggleStyle(CustomToggleStyle())
        .padding()
    }
}
