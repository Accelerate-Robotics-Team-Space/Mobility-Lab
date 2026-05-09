//
//  TextFieldExampleView.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/10/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct InputFieldExampleView: View {
    @State private var inputText = ""
    @State private var textFieldOptionIndex = 0
    @State private var errorStatesIndex = 0
    @State private var charCountIndex = 0
    
    private var errorMsg = "Some Error Msg"
    private let textFieldRequirements = ["No Requirement", "Required", "Optional"]
    private let errorStates = ["No Error", "Some Error"]
    private let charCountStates = ["No Char Count", "Char Count"]

    var body: some View {
        Form {
            Picker(selection: $textFieldOptionIndex, label: Text("")) {
                ForEach(0..<3) {
                    Text(self.textFieldRequirements[$0])
                        .textStyle(.caption)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Picker(selection: $errorStatesIndex, label: Text("")) {
                ForEach(0..<2) {
                    Text(self.errorStates[$0])
                        .textStyle(.caption)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Picker(selection: $charCountIndex, label: Text("")) {
                ForEach(0..<2) {
                    Text(self.charCountStates[$0])
                        .textStyle(.caption)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Text(inputText)
            
            InputField("Some Title",
                       placeholder: "Some Placeholder",
                       inputTxt: $inputText,
                       requirement: .constant(.required),
                       charCount: charCountIndex == 0 ? nil : 15,
                       errorState: errorStatesIndex == 0 ? false : true,
                       errorMsg: errorMsg)
        }
    }
}

struct TextFieldExampleView_Previews: PreviewProvider {
    static var previews: some View {
        InputFieldExampleView()
    }
}
