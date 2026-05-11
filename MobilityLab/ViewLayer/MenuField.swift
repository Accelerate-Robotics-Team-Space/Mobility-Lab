//
//  MenuField.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/12/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct MenuField: View {
    @State private var index = 0
    @State private var backgroundColor = Color.red
    var testOptions = ["one", "two", "three", "four", "five"]
    
    var labelView: some View {
        Text("Some placeholder: \(testOptions[index])")
            .frame(width: 300, alignment: .leading)
            .foregroundColor(.charcoal)
    }
    
    func junk(_ someIndex: Int) -> some View {
        Text("\(testOptions[someIndex]) !?>!!")
            .textStyle(.header1, color: .red)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Some Title")
                    .textStyle(.body1)
                
                Spacer()
                
                Text("(Required)")
                    .textStyle(.subtitle)
            }
            
            .frame(maxWidth: .infinity, alignment: .leading)
            .pickerStyle(MenuPickerStyle())
            
            Picker(selection: $index, label: labelView, content: {
                ForEach(0..<testOptions.count, id: \.self) {
                    junk($0)
                }
            })
            .pickerStyle(MenuPickerStyle())
            .textStyle(.body2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.all, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.charcoal, lineWidth: 2)
            )
            
            HStack {
                if true {
                    Circle()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.vermillion)
                    
                    Text("Some Err Msg")
                        .textStyle(.subtitle, color: .vermillion)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

struct MenuField_Previews: PreviewProvider {
    static var previews: some View {
        MenuField()
    }
}
