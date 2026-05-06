//
//  BtnStylesView.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/10/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BtnStylesView: View {
    @State private var btn1IsOn = false
    @State private var btn2IsOn = false
    @State private var btn3IsOn = false
    @State private var btn4IsOn = false
    @State private var btn5IsOn = false
    @State private var btn6IsOn = false
    @State private var btn7IsOn = false
    @State private var primaryBtnIndex = 0
    @State private var secondaryBtnIndex = 0
    @State private var exitBtnIndex = 0
    
    private var primaryBtnOptinos = ["Default", "Destructive", "Disabled"]
    private var secondaryBtnOptinos = ["Default", "Destructive", "Disabled"]
    private var exitBtnOptinos = ["Primary", "Secondary", "Inactive"]
    private var frameSize: CGFloat = 100
    private var primaryBtnStyle: FlatButtonStyle.Style {
        switch primaryBtnIndex {
        case 0:
            return .primary(subtype: .default)
        case 1:
            return .primary(subtype: .destructive)
        default:
            return .primary(subtype: .disabled)
        }
    }
    
    private var secondaryBtnStyle: FlatButtonStyle.Style {
        switch secondaryBtnIndex {
        case 0:
            return .secondary(subtype: .default)
        case 1:
            return .secondary(subtype: .destructive)
        default:
            return .secondary(subtype: .disabled)
        }
    }
    
    private var exitBtnStyle: FlatButtonStyle.Style {
        switch exitBtnIndex {
        case 0:
            return .primary()
        case 1:
            return .secondary()
        default:
            return .primary(subtype: .disabled)
        }
    }
    
    var body: some View {
        Form {
            // MARK: - Primary Section
            Section(header: Text("Primary").textStyle(.subtitle)) {
                Picker(selection: $primaryBtnIndex, label: Text("")) {
                    ForEach(0..<primaryBtnOptinos.count, id: \.self) {
                        Text(self.primaryBtnOptinos[$0])
                            .textStyle(.caption)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                HStack {
                    Button(action: {
                        btn1IsOn.toggle()
                    }, label: {
                        Text("Button")
                    })
                    .buttonStyle(FlatButtonStyle(primaryBtnStyle))
                    
                    Spacer()
                    
                    Circle()
                        .frame(width: frameSize, height: frameSize)
                        .foregroundColor(btn1IsOn ? .vermillion : .aqua)
                }
                
                HStack {
                    DirectionalBtn(.right, style: primaryBtnStyle, labelStr: "Button") {
                        btn2IsOn.toggle()
                    }
                    
                    Spacer()
                    
                    Circle()
                        .frame(width: frameSize, height: frameSize)
                        .foregroundColor(btn2IsOn ? .vermillion : .aqua)
                }
                
                HStack {
                    DirectionalBtn(.left, style: primaryBtnStyle, labelStr: "Button") {
                        btn3IsOn.toggle()
                    }
                    
                    Spacer()
                    
                    Circle()
                        .frame(width: frameSize, height: frameSize)
                        .foregroundColor(btn3IsOn ? .vermillion : .aqua)
                }
            }
            
            // MARK: - Secondary Section
            Section(header: Text("Secondary").textStyle(.subtitle)) {
                Picker(selection: $secondaryBtnIndex, label: Text("")) {
                    ForEach(0..<secondaryBtnOptinos.count, id: \.self) {
                        Text(self.secondaryBtnOptinos[$0])
                            .textStyle(.caption)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                HStack {
                    Button(action: {
                        btn4IsOn.toggle()
                    }, label: {
                        Text("Button")
                    })
                    .buttonStyle(FlatButtonStyle(secondaryBtnStyle))
                    
                    Spacer()
                    
                    Circle()
                        .frame(width: frameSize, height: frameSize)
                        .foregroundColor(btn4IsOn ? .vermillion : .aqua)
                }
                
                HStack {
                    DirectionalBtn(.right, style: secondaryBtnStyle, labelStr: "Button") {
                        btn5IsOn.toggle()
                    }
                    
                    Spacer()
                    
                    Circle()
                        .frame(width: frameSize, height: frameSize)
                        .foregroundColor(btn5IsOn ? .vermillion : .aqua)
                }
                
                HStack {
                    DirectionalBtn(.left, style: secondaryBtnStyle, labelStr: "Button") {
                        btn6IsOn.toggle()
                    }
                    
                    Spacer()
                    
                    Circle()
                        .frame(width: frameSize, height: frameSize)
                        .foregroundColor(btn6IsOn ? .vermillion : .aqua)
                }
            }
            
            // MARK: - Exit Section
            Section(header: Text("Exit").textStyle(.subtitle)) {
                Picker(selection: $exitBtnIndex, label: Text("")) {
                    ForEach(0..<exitBtnOptinos.count, id: \.self) {
                        Text(self.exitBtnOptinos[$0])
                            .textStyle(.caption)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                HStack {
                    ExitBtn(exitBtnStyle) {
                        btn7IsOn.toggle()
                    }
                    
                    Spacer()
                    
                    Circle()
                        .frame(width: frameSize, height: frameSize)
                        .foregroundColor(btn7IsOn ? .vermillion : .aqua)
                }
            }
        }
        .navigationBarTitle("Button Styles")
    }
}

struct BtnStylesView_Previews: PreviewProvider {
    static var previews: some View {
        BtnStylesView()
    }
}
