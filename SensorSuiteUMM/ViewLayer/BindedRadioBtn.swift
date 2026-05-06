//
//  BindedRadioBtn.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 11/16/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BindedRadioBtn: View {
    @Binding var isSelected: Bool?
    
    private var btnStyle: RadioBtnStyle
    private var btnAction: (Bool) -> Void
    
    private var isBtnSelected: Bool {
        isSelected ?? false
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            isSelected?.toggle()
            btnAction(isBtnSelected)
        }, label: {
            HStack {
                if let imageStr = btnStyle.imageStr {
                    Image(imageStr)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 48, maxHeight: 40)
                        .padding()
                }
                
                VStack(alignment: .leading) {
                    Text(btnStyle.title)
                        .textStyle(.header4, color: isBtnSelected ? .white : .charcoal1)

                    if let bodyStr = btnStyle.bodyStr {
                        Text(bodyStr)
                            .font(.custom("Avenir", size: 16))
                            .foregroundColor(isBtnSelected ? .white : .charcoal)
                    }
                }
                
                Spacer()
                
                Image(isBtnSelected ? R.image.radioTicked.name : R.image.radioUnticked.name)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(isBtnSelected ? .white : .charcoal5)
                    .frame(width: 20, height: 20)
                    .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56)
            .conditionalModifier(isBtnSelected) {
                $0.background(Color.green1)
            }
        })
        
        if btnStyle.imageStr != "position-right-lateral-1" {
            Divider()
                .frame(height: 1)
                .background(Color(red: 0, green: 0, blue: 0, opacity: 0.1))
        }
    }
    
    // MARK: - Init
    init(_ someStyle: RadioBtnStyle, binding: Binding<Bool?>, onToggle: @escaping (Bool) -> Void) {
        self.btnStyle = someStyle
        self._isSelected = binding
        self.btnAction = onToggle
    }
}

struct BindedRadioBtn_Previews: PreviewProvider {
    static var previews: some View {
        BindedRadioBtn(.simple(title: "Some Title"), binding: .constant(false)) { _ in
            // Do stuff
        }
    }
}
